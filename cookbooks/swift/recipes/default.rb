execute "clean-up" do
  command "rm /home/vagrant/postinstall.sh || true"
end

# deadsnakes for py2.6
execute "deadsnakes key" do
  command "sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys DB82666C"
  action :run
end

cookbook_file "/etc/apt/sources.list.d/fkrull-deadsnakes-precise.list" do
  source "etc/apt/sources.list.d/fkrull-deadsnakes-precise.list"
  mode 0644
end

execute "apt-get-update" do
  command "apt-get update && touch /tmp/.apt-get-update"
  creates "/tmp/.apt-get-update"
  action :run
end

# packages
required_packages = [
  "curl", "gcc", "memcached", "rsync", "sqlite3", "xfsprogs", "git-core",
  "build-essential", "python-dev", "libffi-dev", "python-setuptools",
  "python-coverage", "python-dev", "python-nose", "python-simplejson",
  "python-xattr", "python-eventlet", "python-greenlet", "python-pastedeploy",
  "python-netifaces", "python-pip", "python-dnspython", "python-mock",
  "python2.6", "python2.6-dev",
]
extra_packages = node['extra_packages']
(required_packages + extra_packages).each do |pkg|
  package pkg do
    action :install
  end
end

# setup up some disk

[
  "/var/lib/swift",
  "/mnt/swift-disk",
].each do |d|
  directory d do
    action :create
  end
end

execute "create sparse file" do
  command "truncate -s 3GB /var/lib/swift/disk"
  creates "/var/lib/swift/disk"
  action :run
end

execute "create file system" do
  command "mkfs.xfs /var/lib/swift/disk"
  not_if "xfs_admin -l /var/lib/swift/disk"
  action :run
end

execute "update fstab" do
  command "echo '/var/lib/swift/disk /mnt/swift-disk xfs " \
    "loop,noatime,nodiratime,nobarrier,logbufs=8 0 0' >> /etc/fstab"
  not_if "grep swift-disk /etc/fstab"
  action :run
end

execute "mount" do
  command "mount /mnt/swift-disk"
  not_if "mountpoint /mnt/swift-disk"
end

(1..node['disks']).each do |i|
  j = ((i - 1) % node['nodes']) + 1
  disk_path = "/mnt/swift-disk/sdb#{i}"
  node_path = "/srv/node#{j}"
  srv_path = node_path + "/sdb#{i}"
  directory disk_path do
    owner "vagrant"
    group "vagrant"
    action :create
  end
  directory node_path do
    owner "vagrant"
    group "vagrant"
    action :create
  end
  link srv_path do
    to disk_path 
  end
end

# run dirs

[
  "/var/run/swift",
].each do |d|
  directory d do
    owner "vagrant"
    group "vagrant"
    action :create
  end
end

(1..node['nodes']).each do |i|
  recon_cache_path = "/var/cache/swift/node#{i}"
  directory recon_cache_path do
    owner "vagrant"
    group "vagrant"
    recursive true
  end
end

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

# python install

execute "git python-swiftclient" do
  cwd "/vagrant"
  command "git clone git://github.com/openstack/python-swiftclient.git"
  creates "/vagrant/python-swiftclient"
  action :run
end

execute "git swift" do
  cwd "/vagrant"
  command "git clone git://github.com/openstack/swift.git"
  creates "/vagrant/swift"
  action :run
end

execute "python-swiftclient-install" do
  cwd "/vagrant/python-swiftclient"
  command "pip install -e . && pip install -r test-requirements.txt"
  # creates "/usr/local/lib/python2.7/dist-packages/python-swiftclient.egg-link"
  action :run
end

execute "python-swift-install" do
  cwd "/vagrant/swift"
  command "python setup.py develop && pip install -r test-requirements.txt"
  # creates "/usr/local/lib/python2.7/dist-packages/swift.egg-link"
  action :run
end

execute "install tox" do
  command "pip install tox"
end

[
  'swift',
  'python-swiftclient',
].each do |dirname|
  execute "ln #{dirname}" do
    command "ln -s /vagrant/#{dirname} /home/vagrant/#{dirname}"
    creates "/home/vagrant/#{dirname}"
  end
end

# configs
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

# rings

["object", "container", "account"].each_with_index do |service, p|
  execute "#{service}.builder-create" do
    command "sudo -u vagrant swift-ring-builder #{service}.builder create " \
      "#{node['part_power']} #{node['replicas']} 1"
    creates "/etc/swift/#{service}.builder"
    cwd "/etc/swift"
  end
  (1..node['disks']).each do |i|
    j = ((i - 1) % node['nodes']) + 1
    z = ((i - 1) % node['zones']) + 1
    r = ((z - 1) % node['regions']) + 1
    execute "#{service}.builder-add-sdb#{i}" do
      dsl = "r#{r}z#{z}-127.0.0.1:60#{j}#{p}/sdb#{i}"
      command "sudo -u vagrant swift-ring-builder #{service}.builder add " \
        "#{dsl} 1 && rm -f /etc/swift/#{service}.ring.gz || true"
      not_if "swift-ring-builder /etc/swift/#{service}.builder search #{dsl}"
      cwd "/etc/swift"
    end
  end
  execute "#{service}.builder-rebalance" do
    command "sudo -u vagrant swift-ring-builder #{service}.builder write_ring"
    not_if "sudo -u vagrant swift-ring-builder /etc/swift/#{service}.builder rebalance"
    creates "/etc/swift/#{service}.ring.gz"
    cwd "/etc/swift"
  end
end

node['storage_policies'].each_with_index do |name, p|
  service = "object-#{p + 1}"
  execute "#{service}.builder-create" do
    command "sudo -u vagrant swift-ring-builder #{service}.builder create " \
      "#{node['part_power']} #{node['replicas']} 1"
    creates "/etc/swift/#{service}.builder"
    cwd "/etc/swift"
  end
  (1..node['disks']).each do |i|
    j = ((i - 1) % node['nodes']) + 1
    z = ((i - 1) % node['zones']) + 1
    r = ((z - 1) % node['regions']) + 1
    execute "#{service}.builder-add-sdb#{i}" do
      command "sudo -u vagrant swift-ring-builder #{service}.builder add " \
        "r#{r}z#{z}-127.0.0.1:60#{j}0/sdb#{i} 1 && " \
        "rm -f /etc/swift/#{service}.ring.gz || true"
      not_if "swift-ring-builder /etc/swift/#{service}.builder search /sdb#{i}"
      cwd "/etc/swift"
    end
  end
  execute "#{service}.builder-rebalance" do
    command "sudo -u vagrant swift-ring-builder #{service}.builder write_ring"
    not_if "sudo -u vagrant swift-ring-builder /etc/swift/#{service}.builder rebalance"
    creates "/etc/swift/#{service}.ring.gz"
    cwd "/etc/swift"
  end
end

# start main

execute "startmain" do
  command "sudo -u vagrant swift-init start main"
end

# setup environment

execute "update-path" do
  command "echo 'export PATH=/vagrant/bin:$PATH' >> /home/vagrant/.profile"
  not_if "grep /vagrant/bin /home/vagrant/.profile"
  action :run
end

# swift command line env setup
#
{
  "ST_AUTH" => "http://saio:8080/auth/v1.0",
  "ST_USER" => "test:tester",
  "ST_KEY" => "testing",
}.each do |var, value|
  execute "swift-env-#{var}" do
    command "echo 'export #{var}=#{value}' >> /home/vagrant/.profile"
    not_if "grep #{var} /home/vagrant/.profile"
    action :run
  end
end
