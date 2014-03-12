# rsync

cookbook_file "/etc/rsyncd.conf" do
  source "etc/rsyncd.conf"
end

execute "enable-rsync" do
  command "sed -i 's/ENABLE=false/ENABLE=true/' /etc/default/rsync"
  not_if "grep ENABLE=true /etc/default/rsync"
  action :run
end

service "rsync" do
  action :start
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
  })
end

[
  'proxy-server',
  'test',
  'dispersion',
  'bench',
  'object-expirer',
].each do |filename|
  cookbook_file "/etc/swift/#{filename}.conf" do
    source "etc/swift/#{filename}.conf"
    owner "vagrant"
    group "vagrant"
  end
end

["object", "container", "account"].each_with_index do |service, p|
  directory "/etc/swift/#{service}-server" do
    owner "vagrant"
    group "vagrant"
    action :create
  end
  (1..node['nodes']).each do |i|
    template "/etc/swift/#{service}-server/#{i}.conf" do
      source "etc/swift/#{service}-server.conf.erb"
      owner "vagrant"
      group "vagrant"
      variables({
         :srv_path => "/srv/node#{i}",
         :bind_port => "60#{i}#{p}",
         :recon_cache_path => "/var/cache/swift/node#{i}",
         :sync_method => node['object_sync_method'],
      })
    end
  end
end

