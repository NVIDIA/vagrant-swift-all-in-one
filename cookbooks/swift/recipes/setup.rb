#
#Copyright (c) 2015-2021, NVIDIA CORPORATION.
#SPDX-License-Identifier: Apache-2.0

execute "clean-up" do
  command "rm /home/#{node['username']}/postinstall.sh || true"
end

execute 'ensure ssh directory exists' do
  command "mkdir -p ~#{node['username']}/.ssh"
end

if node['extra_key'] then
  keys_file = "~#{node['username']}/.ssh/authorized_keys"
  execute "add_extra_key" do
    command "echo '#{node['extra_key']}' >> #{keys_file}"
    not_if "grep -q '#{node['extra_key']}' #{keys_file}"
  end
end

# deadsnakes for all the pythons
package "software-properties-common" do
  action :install
  not_if "which add-apt-repository"
end

execute "deadsnakes key" do
  command "sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys"
  action :run
  not_if "sudo apt-key list | grep 'Launchpad PPA for deadsnakes'"
end

execute "add repo" do
  command "sudo add-apt-repository ppa:deadsnakes/ppa"
end

execute "apt-get-update" do
  command "apt-get update && touch /tmp/.apt-get-update"
  if not node['full_reprovision']
    creates "/tmp/.apt-get-update"
  end
  action :run
end

systemd_unit "multipathd" do
  # focal boxes generate a lot of useless logs with this guy running
  action [:disable, :stop]
end

# system packages
required_packages = [
  "libssl-dev", # libssl-dev is required for building wheels from the cryptography package in swift.
  "curl", "gcc", "memcached", "rsync", "sqlite3", "xfsprogs", "git", "build-essential",
  "libffi-dev",  "libxml2-dev", "libxml2", "libxslt1-dev", "zlib1g-dev", "autoconf", "libtool",
  "haproxy", "docker-compose", "rclone",
]

# common python versions
required_packages += [
  # most of time these come from deadsnakes
  "python3.7", "python3.7-distutils",
  "python3.8", "python3.8-distutils",
  "python3.9", "python3.9-distutils",
  "python3.10",
  "python3.11",
  "python3.12",
  "python3.13",  # edge of technology!
  # python3 will be redundant with distro version, -dev is needed for pyeclib
  "python3", "python3-dev",
]

# only focal has the *really* old py3
if node['platform_version'].to_i <= 20 then
  required_packages += [
    "python3.6", "python3.6-distutils",
  ]
end

# no-no packages (PIP rules this vm, most system packages are all out-of-date anyway)
unrequired_packages = [
  "python3-pip", "python3-pbr", "python3-setuptools",
  "python3-openssl", "python3-certifi",
  "python3-requests",  "python3-urllib3",
]
unrequired_packages.each do |pkg|
  package pkg do
    action :purge
  end
end

# good-good packages (do the install after purge)
extra_packages = node['extra_packages']
(required_packages + extra_packages).each do |pkg|
  package pkg do
    action :install
  end
end

# see https://peps.python.org/pep-0668/
file 'break system python' do
  path "/etc/pip.conf"
  content <<-EOF
[global]
root-user-action = ignore
break-system-packages = true
EOF
end

# the less system packages the better, we install all python stuff with pip
bash 'install pip' do
  code <<-EOF
    set -o pipefail
    curl "https://bootstrap.pypa.io/get-pip.py" | /usr/bin/env python3
    EOF
  if not node['full_reprovision']
    not_if "which pip"
  end
end

# install pip packages

[
  "s3cmd",
  "awscli-plugin-endpoint",
].each do |pkg|
  execute "pip install #{pkg}" do
    command "pip install #{pkg}"
  end
end

# this works around some PBR/git interaction
cookbook_file "/etc/gitconfig" do
  source "etc/gitconfig"
  owner node['username']
  group node['username']
end

# setup environment

profile_file = "/home/#{node['username']}/.profile"

execute "update-path" do
  command "echo 'export PATH=/vagrant/bin:$PATH' >> #{profile_file}"
  not_if "grep /vagrant/bin #{profile_file}"
  action :run
end

[
  "/vagrant/.functions.sh",
].each do |filename|
  execute "source-#{filename}" do
    command "echo 'source #{filename}' >> #{profile_file}"
    not_if "grep 'source #{filename}' #{profile_file}"
  end
end

cookbook_file "/home/#{node['username']}/.nanorc" do
  source "home/nanorc"
  owner node['username']
  group node['username']
end


# swift command line env setup

{
  "ST_AUTH" => node['auth_uri'],
  "ST_USER" => "test:tester",
  "ST_KEY" => "testing",
  "OS_AUTH_URL" => "http://#{node['hostname']}:8080/auth/v1.0",
  "OS_USERNAME" => "test:tester",
  "OS_PASSWORD" => "testing",
}.each do |var, value|
  execute "swift-env-#{var}" do
    command "echo 'export #{var}=#{value}' >> #{profile_file}"
    not_if "grep #{var} #{profile_file} && " \
      "sed '/#{var}/c\\export #{var}=#{value}' -i #{profile_file}"
    action :run
  end
end


# s3cmd setup

template "/home/#{node['username']}/.s3cfg" do
  source "/home/s3cfg.erb"
  owner node['username']
  group node['username']
  mode 0700
  variables({
    :ssl => node['ssl'],
  })
end

# awscli setup

directory "/home/#{node['username']}/.aws" do
  owner node['username']
  group node['username']
  mode 0700
  action :create
end
template "/home/#{node['username']}/.aws/config" do
  source "/home/aws/config.erb"
  owner node['username']
  group node['username']
  mode 0700
  variables({
    :base_uri => node['base_uri'],
  })
end
template "/home/#{node['username']}/.aws/credentials" do
  source "/home/aws/credentials.erb"
  owner node['username']
  group node['username']
  mode 0700
end

execute "enable bash completer for awscli" do
  command "ln -s $(which aws_bash_completer) /etc/bash_completion.d/"
  creates "/etc/bash_completion.d/aws_bash_completer"
end

# rclone setup
# ~/.config/rclone/rclone.conf
directory "/home/#{node['username']}/.config/rclone" do
  owner node['username']
  group node['username']
  recursive true
  mode 0700
  action :create
end
template "/home/#{node['username']}/.config/rclone/rclone.conf" do
  source "/home/rclone/rclone.erb"
  owner node['username']
  group node['username']
  mode 0700
  variables({
    :ssl => node['ssl'],
    :hostname => node['hostname'],
    :base_uri => node['base_uri'],
    :auth_uri => node['auth_uri'],
  })
end

# other useful env vars

{
  "SOURCE_ROOT" => "#{node['source_root']}",
  "NOSE_INCLUDE_EXE" => "true",
  "TMPDIR" => "/mnt/tmp",
}.each do |var, value|
  execute "swift-env-#{var}" do
    command "echo 'export #{var}=#{value}' >> #{profile_file}"
    not_if "grep #{var} #{profile_file} && " \
      "sed '/#{var}/c\\export #{var}=#{value}' -i #{profile_file}"
    action :run
  end
end
