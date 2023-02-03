#
#Copyright (c) 2015-2021, NVIDIA CORPORATION.
#SPDX-License-Identifier: Apache-2.0

# rsync

template "/etc/rsyncd.conf" do
  source "etc/rsyncd.conf.erb"
  notifies :restart, 'service[rsync]'
  variables({
    :username => node['username'],
  })
end

execute "enable-rsync" do
  command "sed -i 's/ENABLE=false/ENABLE=true/' /etc/default/rsync"
  not_if "grep ENABLE=true /etc/default/rsync"
  action :run
end

# pre device rsync modules

directory "/etc/rsyncd.d" do
  owner "vagrant"
  group "vagrant"
  action :create
end

["container", "account"].each do |service|
  (1..node['disks']).each do |i|
    dev = "sdb#{i}"
    n = ((i - 1) % node['nodes']) + 1
    template "/etc/rsyncd.d/#{service}_#{dev}.conf" do
      source "/etc/rsyncd.d/rsync_disk.erb"
      owner "vagrant"
      group "vagrant"
      variables({
        :service => service,
        :dev => dev,
        :n => n,
      })
    end
  end
end

(1..[node['disks'], node['ec_disks']].max).each do |i|
  dev = "sdb#{i}"
  n = ((i - 1) % node['nodes']) + 1
  template "/etc/rsyncd.d/object_#{dev}.conf" do
    source "/etc/rsyncd.d/rsync_disk.erb"
    owner "vagrant"
    group "vagrant"
    variables({
      :service => "object",
      :dev => "sdb#{i}",
      :n => n,
    })
  end
end

# services

[
  "rsync",
  "memcached",
  "rsyslog",
].each do |daemon|
  service daemon do
    action :start
  end
end

# haproxy

execute "create key" do
  command "openssl genpkey -algorithm EC -out saio.key " \
    "-pkeyopt ec_paramgen_curve:prime256v1 " \
    "-pkeyopt ec_param_enc:named_curve"
  #command "openssl genpkey -algorithm RSA -out saio.key " \
  #  "-pkeyopt rsa_keygen_bits:2048"
  cwd "/etc/ssl/private/"
  creates "/etc/ssl/private/saio.key"
end

template "/etc/ssl/private/saio.conf" do
  source "/etc/ssl/private/saio.conf.erb"
  variables({
    :ip => node["ip"],
    :hostname => node["hostname"],
  })
end

execute "create cert" do
  command "openssl req -x509 -days 365 -key saio.key " \
    "-out saio.crt -config saio.conf"
  cwd "/etc/ssl/private/"
  creates "/etc/ssl/private/saio.crt"
end

execute "install cert" do
  cert_to_install = "/etc/ssl/private/saio.crt"
  command "mkdir -p /usr/local/share/ca-certificates/extra && " \
    "cp #{cert_to_install} /usr/local/share/ca-certificates/extra/saio_ca.crt && " \
    "update-ca-certificates && " \
    "cat #{cert_to_install} >> $(python -m certifi)"
  creates "/usr/local/share/ca-certificates/extra/saio_ca.crt"
end

if node['full_reprovision'] then
  execute "reinstall cert for certifi" do
    cert_to_install = "/etc/ssl/private/saio.crt"
    command "cat #{cert_to_install} >> $(python -m certifi)"
  end
end

execute "create pem" do
  command "cat saio.crt saio.key > saio.pem"
  cwd "/etc/ssl/private/"
  creates "/etc/ssl/private/saio.pem"
end

cookbook_file "/etc/haproxy/haproxy.cfg" do
  source "etc/haproxy/haproxy.cfg"
  notifies :restart, 'service[haproxy]'
  owner node['username']
  group node['username']
end

service "haproxy" do
  if node['ssl'] then
    action :start
  else
    action :stop
  end
end

# swift

directory "/etc/swift" do
  owner node['username']
  group node["username"]
  action :create
end

template "/etc/rc.local" do
  # Make /var/run/swift/ survive reboots
  source "etc/rc.local.erb"
  mode 0755
  variables({
    :username => node['username'],
  })
end

[
  'bench.conf',
  'keymaster.conf',
].each do |filename|
  cookbook_file "/etc/swift/#{filename}" do
    source "etc/swift/#{filename}"
    owner node["username"]
    group node["username"]
  end
end

[
  'base.conf-template',
  'dispersion.conf',
  'container-sync-realms.conf',
  'test.conf',
  'swift.conf',
].each do |filename|
  template "/etc/swift/#{filename}" do
    source "/etc/swift/#{filename}.erb"
    owner node["username"]
    group node["username"]
    variables({}.merge(node))
  end
end

# proxies

directory "/etc/swift/proxy-server" do
  owner node["username"]
  group node["username"]
end

template "/etc/swift/proxy-server/default.conf-template" do
  source "etc/swift/proxy-server/default.conf-template.erb"
  owner node["username"]
  group node["username"]
  variables({
    :disable_encryption => ! node['encryption'],
  })
end

[
  "proxy-server",
  "proxy-noauth",
].each do |proxy|
  proxy_conf_dir = "etc/swift/proxy-server/#{proxy}.conf.d"
  directory proxy_conf_dir do
    owner node["username"]
    group node["username"]
    action :create
  end
  link "/#{proxy_conf_dir}/00_base.conf" do
    to "/etc/swift/base.conf-template"
    owner node["username"]
    group node["username"]
  end
  link "/#{proxy_conf_dir}/10_default.conf" do
    to "/etc/swift/proxy-server/default.conf-template"
    owner node["username"]
    group node["username"]
  end
  if proxy == "proxy-noauth" then
    cookbook_file "#{proxy_conf_dir}/20_settings.conf" do
      source "#{proxy_conf_dir}/20_settings.conf"
      owner node["username"]
      group node["username"]
    end
  else
    if node['kmip'] then
      keymaster_pipeline = 'kmip_keymaster'
    else
      keymaster_pipeline = 'keymaster'
    end
    template "/#{proxy_conf_dir}/20_settings.conf" do
      source "#{proxy_conf_dir}/20_settings.conf.erb"
      owner node["username"]
      group node["username"]
      variables({
        :ssl => node['ssl'],
        :keymaster_pipeline => keymaster_pipeline,
      })
    end
  end
end

(1..node['nodes']).each do |i|
  template "/etc/swift/node#{i}.conf-template" do
    source "/etc/swift/node.conf-template.erb"
    owner node["username"]
    group node["username"]
    variables({
       :srv_path => "/srv/node#{i}",
       :bind_ip => "127.0.0.#{i}",
       :recon_cache_path => "/var/cache/swift/node#{i}",
    })
  end
end

[:object, :container, :account].each_with_index do |service, p|
  service_dir = "etc/swift/#{service}-server"
  directory "/#{service_dir}" do
    owner node["username"]
    group node["username"]
    action :create
  end
  template "/#{service_dir}/server.conf-template" do
    source "#{service_dir}/server.conf-template.erb"
    owner node["username"]
    group node["username"]
    variables({
      :servers_per_port => node['servers_per_port'],
      :replication_server => !node["replication_servers"],
    })
  end
  if node["replication_servers"] then
    template "/#{service_dir}/replication-server.conf-template" do
      source "#{service_dir}/server.conf-template.erb"
      owner node["username"]
      group node["username"]
      variables({
        :servers_per_port => node['servers_per_port'],
        :replication_server => true,
      })
    end
  else
    file "/#{service_dir}/replication-server.conf-template" do
      action :delete
    end
  end
  template "/#{service_dir}/replication-daemons.conf-template" do
    source "#{service_dir}/replication.conf-template.erb"
    owner node["username"]
    group node["username"]
    variables({
      :auto_shard => node['container_auto_shard'],
      :sync_method => node['object_sync_method'],
    })
  end
  (1..node['nodes']).each do |i|
    bind_port = 6000 + 10 * i + p
    replication_bind_port = 6000 + 10 * (i + node['nodes']) + p
    if service == :object && node['servers_per_port'] > 0 then
      # These config settings shouldn't really matter in the server-per-port
      # scenario, but they should probably at least be equal to one of the actual
      # ports in the ring.
      bind_port = 6000 + 10 * i + 6
      replication_bind_port = 6000 + 10 * (i + node['nodes']) + 6
    end
    server_conf_dir = "#{service_dir}/#{i}.conf.d"
    replication_conf_dir = "#{service_dir}/#{i + node['nodes']}-replication.conf.d"
    directory "/#{server_conf_dir}" do
      owner node["username"]
      group node["username"]
    end
    link "/#{server_conf_dir}/00_base.conf" do
      to "/etc/swift/base.conf-template"
      owner node["username"]
      group node["username"]
    end
    link "/#{server_conf_dir}/10_node.conf" do
      to "/etc/swift/node#{i}.conf-template"
      owner node["username"]
      group node["username"]
    end
    link "/#{server_conf_dir}/20_server.conf" do
      to "/#{service_dir}/server.conf-template"
      owner node["username"]
      group node["username"]
    end
    template "/#{server_conf_dir}/30_settings.conf" do
      source "#{service_dir}/settings.conf.erb"
      owner node["username"]
      group node["username"]
      variables({
       :bind_port => bind_port,
       :include_replication_settings => !node["replication_servers"],
      })
    end
    if node["replication_servers"] then
      file "/#{server_conf_dir}/40_replication.conf" do
        action :delete
      end
      directory "/#{replication_conf_dir}" do
        owner node["username"]
        group node["username"]
      end
      link "/#{replication_conf_dir}/00_base.conf" do
        to "/etc/swift/base.conf-template"
        owner node["username"]
        group node["username"]
      end
      link "/#{replication_conf_dir}/10_node.conf" do
        to "/etc/swift/node#{i}.conf-template"
        owner node["username"]
        group node["username"]
      end
      link "/#{replication_conf_dir}/20_server.conf" do
        to "/#{service_dir}/replication-server.conf-template"
        owner node["username"]
        group node["username"]
      end
      template "/#{replication_conf_dir}/30_settings.conf" do
        source "#{service_dir}/settings.conf.erb"
        owner node["username"]
        group node["username"]
        variables({
         :bind_port => replication_bind_port,
         :include_replication_settings => true,
        })
      end
      link "/#{replication_conf_dir}/40_replication.conf" do
        to "/#{service_dir}/replication-daemons.conf-template"
        owner node["username"]
        group node["username"]
      end
    else
      directory "/#{replication_conf_dir}" do
        action :delete
        recursive true
      end
      link "/#{server_conf_dir}/40_replication.conf" do
        to "/#{service_dir}/replication-daemons.conf-template"
        owner node["username"]
        group node["username"]
      end
    end
  end
end

# object-expirer
directory "/etc/swift/object-expirer.conf.d" do
  owner node["username"]
  group node["username"]
  action :create
end
link "/etc/swift/object-expirer.conf.d/00_base.conf" do
  to "/etc/swift/base.conf-template"
  owner node["username"]
  group node["username"]
end
cookbook_file "/etc/swift/object-expirer.conf.d/20_settings.conf" do
  source "etc/swift/object-expirer.conf.d/20_settings.conf"
  owner node["username"]
  group node["username"]
end

# container-reconciler
directory "/etc/swift/container-reconciler.conf.d" do
  owner node["username"]
  group node["username"]
  action :create
end
link "/etc/swift/container-reconciler.conf.d/00_base.conf" do
  to "/etc/swift/base.conf-template"
  owner node["username"]
  group node["username"]
end
cookbook_file "/etc/swift/container-reconciler.conf.d/20_settings.conf" do
  source "etc/swift/container-reconciler.conf.d/20_settings.conf"
  owner node["username"]
  group node["username"]
end

# internal-client.conf
if node['kmip'] then
  keymaster_pipeline = 'kmip_keymaster'
else
  keymaster_pipeline = 'keymaster'
end
template "/etc/swift/internal-client.conf" do
  source "etc/swift/internal-client.conf.erb"
  owner node["username"]
  owner node["username"]
  variables({
    :disable_encryption => ! node['encryption'],
    :keymaster_pipeline => keymaster_pipeline,
  })
end
