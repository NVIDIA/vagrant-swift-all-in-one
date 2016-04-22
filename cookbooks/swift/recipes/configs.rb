# Copyright (c) 2015 SwiftStack, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# rsync

cookbook_file "/etc/rsyncd.conf" do
  source "etc/rsyncd.conf"
  notifies :restart, 'service[rsync]'
end

execute "enable-rsync" do
  command "sed -i 's/ENABLE=false/ENABLE=true/' /etc/default/rsync"
  not_if "grep ENABLE=true /etc/default/rsync"
  action :run
end

execute "enable-udp-syslog" do
  command "sed -i 's/# $ModLoad imudp/$ModLoad imudp/;" \
    "s/# $UDPServerRun 514/$UDPServerRun 514/' /etc/rsyslog.conf"
  action :run
end

[
  "rsync",
  "memcached",
  "rsyslog",
].each do |daemon|
  service daemon do
    action :restart
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
    :ec_replicas => node['ec_replicas'],
  })
end

[
  'test.conf',
  'dispersion.conf',
  'bench.conf',
  'bench-direct.conf',
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

template "/etc/swift/proxy-server/default.conf-template" do
  source "etc/swift/proxy-server/default.conf-template.erb"
  owner "vagrant"
  group "vagrant"
  variables({
    :post_as_copy => node['post_as_copy'],
  })
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

# config directories
def do_config_directory(node, service, service_dir, p)
  if service == "object" then
    template "/#{service_dir}/default.conf-template" do
      source "#{service_dir}/default.conf-template.erb"
      owner "vagrant"
      group "vagrant"
      variables({
        :sync_method => node['object_sync_method'],
        :servers_per_port => node['servers_per_port'],
      })
    end
  else
    cookbook_file "/#{service_dir}/default.conf-template" do
      source "#{service_dir}/default.conf-template"
      owner "vagrant"
      group "vagrant"
    end
  end
  (1..node['nodes']).each do |i|
    bind_ip = "127.0.0.1"
    bind_port = "60#{i}#{p}"
    if service == "object" && node['servers_per_port'] > 0 then
      # Only use unique IPs if servers_per_port is enabled.  This lets this
      # newer vagrant-swift-all-in-one work with older swift that doesn't have
      # the required whataremyips() plumbing to make unique IPs work.
      bind_ip = "127.0.0.#{i}"

      # This config setting shouldn't really matter in the server-per-port
      # scenario, but it should probably at least be equal to one of the actual
      # ports in the ring.
      bind_port = "60#{i}6"
    end
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
         :bind_ip => bind_ip,
         :bind_port => bind_port,
         :recon_cache_path => "/var/cache/swift/node#{i}",
      })
    end
  end
end

def do_flat_config(node, service, service_dir, p)
  (1..node['nodes']).each do |i|
    template "/#{service_dir}/#{i}.conf" do
      source "#{service_dir}/flat.conf.erb"
      owner "vagrant"
      group "vagrant"
      variables({
        :sync_method => node['object_sync_method'],
         :srv_path => "/srv/node#{i}",
         :bind_port => "60#{i}#{p}",
         :recon_cache_path => "/var/cache/swift/node#{i}",
      })
    end
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
    do_flat_config node, service, service_dir, p
  else
    do_config_directory node, service, service_dir, p
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
