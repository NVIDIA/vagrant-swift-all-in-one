# rsync

cookbook_file "/etc/rsyncd.conf" do
  source "etc/rsyncd.conf"
end

execute "enable-rsync" do
  command "sed -i 's/ENABLE=false/ENABLE=true/' /etc/default/rsync"
  not_if "grep ENABLE=true /etc/default/rsync"
  action :run
end

[
  "rsync",
  "memcached",
  "rsyslog",
].each do |daemon|
  service daemon do
    action :start
  end
end

# swift

directory "/etc/swift" do
  owner "vagrant"
  group "vagrant"
  action :create
end

template "/etc/swift/swift.conf" do
  source "/etc/swift/swift.conf.erb"
  owner "vagrant"
  group "vagrant"
  variables({
    :storage_policies => node['storage_policies'],
    :ec_policy => node['ec_policy'],
  })
end

[
  'test.conf',
  'dispersion.conf',
  'bench.conf',
  'base.conf-template',
  'container-sync-realms.conf'
].each do |filename|
  cookbook_file "/etc/swift/#{filename}" do
    source "etc/swift/#{filename}"
    owner "vagrant"
    group "vagrant"
  end
end

# proxies

directory "/etc/swift/proxy-server" do
  owner "vagrant"
  group "vagrant"
end

cookbook_file "/etc/swift/proxy-server/default.conf-template" do
  source "etc/swift/proxy-server/default.conf-template"
  owner "vagrant"
  group "vagrant"
end

[
  "proxy-server",
  "proxy-noauth",
].each do |proxy|
  proxy_conf_dir = "etc/swift/proxy-server/#{proxy}.conf.d"
  directory proxy_conf_dir do
    owner "vagrant"
    group "vagrant"
    action :create
  end
  link "/#{proxy_conf_dir}/00_base.conf" do
    to "/etc/swift/base.conf-template"
    owner "vagrant"
    group "vagrant"
  end
  link "/#{proxy_conf_dir}/10_default.conf" do
    to "/etc/swift/proxy-server/default.conf-template"
    owner "vagrant"
    group "vagrant"
  end
  cookbook_file "#{proxy_conf_dir}/20_settings.conf" do
    source "#{proxy_conf_dir}/20_settings.conf"
    owner "vagrant"
    group "vagrant"
  end
end

["object", "container", "account"].each_with_index do |service, p|
  service_dir = "etc/swift/#{service}-server"
  directory "/#{service_dir}" do
    owner "vagrant"
    group "vagrant"
    action :create
  end
  if service == "object" then
    template "/#{service_dir}/default.conf-template" do
      source "#{service_dir}/default.conf-template.erb"
      owner "vagrant"
      group "vagrant"
      variables({:sync_method => node['object_sync_method']})
    end
  else
    cookbook_file "/#{service_dir}/default.conf-template" do
      source "#{service_dir}/default.conf-template"
      owner "vagrant"
      group "vagrant"
    end
  end
  (1..node['nodes']).each do |i|
    conf_dir = "#{service_dir}/#{i}.conf.d"
    directory "/#{conf_dir}" do
      owner "vagrant"
      group "vagrant"
    end
    link "/#{conf_dir}/00_base.conf" do
      to "/etc/swift/base.conf-template"
      owner "vagrant"
      group "vagrant"
    end
    link "/#{conf_dir}/10_default.conf" do
      to "/#{service_dir}/default.conf-template"
      owner "vagrant"
      group "vagrant"
    end
    template "/#{conf_dir}/20_settings.conf" do
      source "#{service_dir}/settings.conf.erb"
      owner "vagrant"
      group "vagrant"
      variables({
         :srv_path => "/srv/node#{i}",
         :bind_port => "60#{i}#{p}",
         :recon_cache_path => "/var/cache/swift/node#{i}",
      })
    end
  end
end

# object-expirer
directory "/etc/swift/object-expirer.conf.d" do
  owner "vagrant"
  group "vagrant"
  action :create
end
link "/etc/swift/object-expirer.conf.d/00_base.conf" do
  to "/etc/swift/base.conf-template"
  owner "vagrant"
  group "vagrant"
end
cookbook_file "/etc/swift/object-expirer.conf.d/20_settings.conf" do
  source "etc/swift/object-expirer.conf.d/20_settings.conf"
  owner "vagrant"
  group "vagrant"
end

# container-reconciler
directory "/etc/swift/container-reconciler.conf.d" do
  owner "vagrant"
  group "vagrant"
  action :create
end
link "/etc/swift/container-reconciler.conf.d/00_base.conf" do
  to "/etc/swift/base.conf-template"
  owner "vagrant"
  group "vagrant"
end
cookbook_file "/etc/swift/container-reconciler.conf.d/20_settings.conf" do
  source "etc/swift/container-reconciler.conf.d/20_settings.conf"
  owner "vagrant"
  group "vagrant"
end
