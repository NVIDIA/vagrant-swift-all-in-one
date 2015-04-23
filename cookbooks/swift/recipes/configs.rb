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
    :ec_replicas => node['ec_replicas'],
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

["object", "container", "account"].each_with_index do |service, p|
  service_dir = "etc/swift/#{service}-server"
  directory "/#{service_dir}" do
    owner "vagrant"
    group "vagrant"
    action :create
  end
  cookbook_file "/#{service_dir}/server.conf-template" do
    source "#{service_dir}/server.conf-template"
    owner "vagrant"
    group "vagrant"
  end
  template "/#{service_dir}/service.conf-template" do
    source "#{service_dir}/service.conf-template.erb"
    owner "vagrant"
    group "vagrant"
    variables({:replication_servers => true})
  end
  template "/#{service_dir}/replication.conf-template" do
    source "#{service_dir}/replication.conf-template.erb"
    owner "vagrant"
    group "vagrant"
    variables({
      :replication_servers => true,
      :sync_method => node['object_sync_method'],
    })
  end
  (1..node['nodes']).each do |i|
    # in non-replication servers this doesn't need to be a conf-template
    template "/#{service_dir}/#{i}.conf-template" do
      source "#{service_dir}/node.conf-template.erb"
      owner "vagrant"
      group "vagrant"
      variables({
        :srv_path => "/srv/node#{i}",
        # :bind_port => "60#{i}#{p}",
        :recon_cache_path => "/var/cache/swift/node#{i}",
      })
    end
    service_conf_dir = "#{service_dir}/#{i}-server.conf.d"
    replication_conf_dir = "#{service_dir}/#{i}-replication.conf.d"
    {
      service_conf_dir => "60#{i}#{p}",
      replication_conf_dir  => "70#{i}#{p}",
    }.each do |conf_dir, bind_port|
      directory "/#{conf_dir}" do
        owner "vagrant"
        group "vagrant"
      end
      link "/#{conf_dir}/00_base.conf" do
        to "/etc/swift/base.conf-template"
        owner "vagrant"
        group "vagrant"
      end
      link "/#{conf_dir}/10_server.conf" do
        to "/#{service_dir}/server.conf-template"
        owner "vagrant"
        group "vagrant"
      end
      link "/#{conf_dir}/40_node.conf" do
        to "/#{service_dir}/#{i}.conf-template"
        owner "vagrant"
        group "vagrant"
      end
      template "/#{conf_dir}/50_settings.conf" do
        source "#{service_dir}/settings.conf.erb"
        owner "vagrant"
        group "vagrant"
        variables({:bind_port => bind_port})
      end
    end
    link "/#{service_conf_dir}/20_service.conf" do
      to "/#{service_dir}/service.conf-template"
      owner "vagrant"
      group "vagrant"
    end
    link "/#{replication_conf_dir}/30_replication.conf" do
      to "/#{service_dir}/replication.conf-template"
      owner "vagrant"
      group "vagrant"
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
