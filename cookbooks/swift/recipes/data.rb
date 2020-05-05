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

if node['ec_policy'].empty? then
  num_disks = node['disks']
else
  num_disks = [node['disks'], node['ec_disks']].max
end

(1..num_disks).each do |i|
  j = ((i - 1) % node['nodes']) + 1
  disk_file = "/var/lib/swift/disk#{i}"
  node_path = "/srv/node#{j}"
  mount_path = node_path + "/sdb#{i}"


  execute "create sparse file #{i}" do
    command "truncate -s #{node['loopback_gb']}GB #{disk_file}"
    creates "#{disk_file}"
    action :run
  end

  execute "create file system" do
    command "mkfs.xfs #{disk_file}"
    not_if "xfs_admin -l #{disk_file}"
    action :run
  end

  directory mount_path do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :create
  end

  execute "update fstab for #{disk_file}" do
    command "echo '#{disk_file} #{mount_path} xfs " \
      "loop,noatime 0 0' >> /etc/fstab"
    not_if "grep #{mount_path} /etc/fstab"
    action :run
  end

  execute "mount" do
    command "mount #{mount_path}"
    not_if "mountpoint #{mount_path}"
  end

  # Fix perms on mounted dir
  directory mount_path do
    owner node["username"]
    group node["username"]
    mode '0775'
  end
end

# for unittest xfs scratch
directory "/srv/node1/sdb1/tmp" do
  owner node["username"]
  group node["username"]
  action :create
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
