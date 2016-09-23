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
  owner node['username']
  group node["username"]
  action :create
end

template "/etc/swift/swift.conf" do
  source "/etc/swift/swift.conf.erb"
  owner node["username"]
  group node["username"]
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
  'container-sync-realms.conf',
].each do |filename|
  cookbook_file "/etc/swift/#{filename}" do
    source "etc/swift/#{filename}"
    owner node["username"]
    group node["username"]
  end
end

template "/etc/swift/base.conf-template" do
  source "etc/swift/base.conf-template.erb"
  variables({
    :username => node['username'],
  })
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
    :post_as_copy => node['post_as_copy'],
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
  cookbook_file "#{proxy_conf_dir}/20_settings.conf" do
    source "#{proxy_conf_dir}/20_settings.conf"
    owner node["username"]
    group node["username"]
  end
end

["object", "container", "account"].each_with_index do |service, p|
  service_dir = "etc/swift/#{service}-server"
  directory "/#{service_dir}" do
    owner node["username"]
    group node["username"]
    action :create
  end
  if service == "object" then
    template "/#{service_dir}/default.conf-template" do
      source "#{service_dir}/default.conf-template.erb"
      owner node["username"]
      group node["username"]
      variables({
        :sync_method => node['object_sync_method'],
        :servers_per_port => node['servers_per_port'],
      })
    end
  else
    cookbook_file "/#{service_dir}/default.conf-template" do
      source "#{service_dir}/default.conf-template"
      owner node["username"]
      group node["username"]
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
      owner node["username"]
      group node["username"]
    end
    link "/#{conf_dir}/00_base.conf" do
      to "/etc/swift/base.conf-template"
      owner node["username"]
      group node["username"]
    end
    link "/#{conf_dir}/10_default.conf" do
      to "/#{service_dir}/default.conf-template"
      owner node["username"]
      group node["username"]
    end
    template "/#{conf_dir}/20_settings.conf" do
      source "#{service_dir}/settings.conf.erb"
      owner node["username"]
      group node["username"]
      variables({
         :srv_path => "/srv/node#{i}",
         :bind_ip => bind_ip,
         :bind_port => bind_port,
         :recon_cache_path => "/var/cache/swift/node#{i}",
      })
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
template "/etc/swift/internal-client.conf" do
  source "etc/swift/internal-client.conf.erb"
  owner node["username"]
  owner node["username"]
  variables({
    :disable_encryption => ! node['encryption'],
  })
end
