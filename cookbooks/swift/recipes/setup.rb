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

# deadsnakes for py2.6
execute "deadsnakes key" do
  command "sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys"
  action :run
  not_if "sudo apt-key list | grep 'Launchpad PPA for deadsnakes'"
end

execute "add repo" do
  command "sudo add-apt-repository ppa:deadsnakes/ppa"
end

# backports seems to be enabled on xenial already?
execute "enable backports" do
  command "sudo sed -ie 's/# deb http:\\/\\/archive.ubuntu.com\\/ubuntu trusty-backports/deb http:\\/\\/archive.ubuntu.com\\/ubuntu trusty-backports/' /etc/apt/sources.list"
  action :run
  not_if "sudo grep -q '^deb .* trusty-backports' /etc/apt/sources.list"
end

execute "apt-get-update" do
  command "apt-get update && touch /tmp/.apt-get-update"
  if not node['full_reprovision']
    creates "/tmp/.apt-get-update"
  end
  action :run
end

# packages
required_packages = [
  "libssl-dev", # libssl-dev is required for building wheels from the cryptography package in swift.
  "curl", "gcc", "memcached", "rsync", "sqlite3", "xfsprogs", "git-core", "build-essential",
  "python-dev", "libffi-dev", "python3.5", "python3.5-dev",
  "python3.6", "python3.6-dev", "python3.7", "python3.7-dev",
  "libxml2-dev", "libxml2", "libxslt1-dev", "autoconf", "libtool", "openjdk-11-jre-headless", "haproxy",
]
extra_packages = node['extra_packages']
(required_packages + extra_packages).each do |pkg|
  package pkg do
    action :install
  end
end

# no-no packages (PIP is the bomb, system packages are OLD SKOOL)
unrequired_packages = [
  "python-requests",  "python-six", "python-urllib3",
  "python-pbr", "python-pip",
]
unrequired_packages.each do |pkg|
  package pkg do
    action :purge
  end
end

execute "select default python version" do
  default_python = node['use_python3'] ? 'python3' : 'python2'
  command "ln -sf #{default_python} /usr/bin/python"
end

# it's a brave new world
bash 'install pip' do
  code <<-EOF
    set -o pipefail
    curl https://bootstrap.pypa.io/get-pip.py | python
    EOF
  if not node['full_reprovision']
    not_if "which pip"
  end
end

# pip 8.0 is more or less broken on trusty -> https://github.com/pypa/pip/issues/3384
execute "upgrade pip" do
  command "pip install --upgrade 'pip>=8.0.2'"
end

execute "fix pip warning 1" do
  command "sed '/env_reset/a Defaults\talways_set_home' -i /etc/sudoers"
  not_if "grep always_set_home /etc/sudoers"
end

execute "fix pip warning 2" do
  command "pip install --upgrade ndg-httpsclient"
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

if node['zipkin'] then
  [
    "py-zipkin",
  ].each do |pkg|
    execute "pip install #{pkg}" do
      command "pip install #{pkg}"
    end
  end
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


# swift command line env setup

{
  "ST_AUTH" => node['auth_uri'],
  "ST_USER" => "test:tester",
  "ST_KEY" => "testing",
  "OS_AUTH_TYPE" => "v1password",
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

execute "enable bash completer for awscli" do
  command "ln -s $(which aws_bash_completer) /etc/bash_completion.d/"
  creates "/etc/bash_completion.d/aws_bash_completer"
end


# other useful env vars

{
  "SOURCE_ROOT" => "#{node['source_root']}",
  "NOSE_INCLUDE_EXE" => "true",
  "TMPDIR" => "/srv/node1/sdb1/tmp",
}.each do |var, value|
  execute "swift-env-#{var}" do
    command "echo 'export #{var}=#{value}' >> #{profile_file}"
    not_if "grep #{var} #{profile_file} && " \
      "sed '/#{var}/c\\export #{var}=#{value}' -i #{profile_file}"
    action :run
  end
end
