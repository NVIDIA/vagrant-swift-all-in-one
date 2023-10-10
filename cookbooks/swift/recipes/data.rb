#
#Copyright (c) 2015-2021, NVIDIA CORPORATION.
#SPDX-License-Identifier: Apache-2.0

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

def make_disk(disk_file, mount_path, size="#{node['loopback_gb']}GB")
  execute "create sparse file #{disk_file}" do
    command "truncate -s #{size} #{disk_file}"
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

(1..num_disks).each do |i|
  j = ((i - 1) % node['nodes']) + 1
  make_disk "/var/lib/swift/disk#{i}", "/srv/node#{j}/sdb#{i}"
end

# for unittest xfs scratch
make_disk "/var/lib/swift/tmp-disk", "/mnt/tmp", "400MB"

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

# make vagrant able to docker
group "docker" do
  action :modify
  members node["username"]
  append true
end
