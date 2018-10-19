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
  command "truncate -s #{node['loopback_gb']}GB /var/lib/swift/disk"
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

# for unittest xfs scratch
directory "/mnt/swift-disk/tmp" do
  owner node["username"]
  group node["username"]
  action :create
end

if node['ec_policy'].empty? then
  num_disks = node['disks']
else
  num_disks = [node['disks'], node['ec_disks']].max
end

(1..num_disks).each do |i|
  j = ((i - 1) % node['nodes']) + 1
  disk_path = "/mnt/swift-disk/sdb#{i}"
  node_path = "/srv/node#{j}"
  srv_path = node_path + "/sdb#{i}"
  directory disk_path do
    owner node["username"]
    group node["username"]
    action :create
  end
  directory "create node path for #{disk_path}" do
    path node_path
    owner node["username"]
    group node["username"]
    action :create
  end
  execute "create .ismount stub for #{disk_path}" do
    command "touch #{disk_path}/.ismount"
    creates "#{disk_path}/.ismount"
    action :run
  end
  link srv_path do
    to disk_path 
  end
end

# run dirs

[
  "/var/run/swift",
  "/var/cache/swift",
].each do |d|
  directory d do
    owner node["username"]
    group node["username"]
    action :create
  end
end

(1..node['nodes']).each do |i|
  recon_cache_path = "/var/cache/swift/node#{i}"
  directory recon_cache_path do
    owner node["username"]
    group node["username"]
    recursive true
  end
end

# make vagrant able to read /var/log/syslog
group "adm" do
  action :modify
  members node["username"]
  append true
end
