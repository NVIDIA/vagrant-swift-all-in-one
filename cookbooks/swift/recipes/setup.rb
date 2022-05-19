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
    default_env true
  end
end

if node['use_python3']
  default_python = 'python3'
  default_pip = 'pip3'
  node.default['pip_url'] = 'https://bootstrap.pypa.io/get-pip.py'
else
  default_python = 'python2'
  default_pip = 'pip2'
  node.default['pip_url'] = 'https://bootstrap.pypa.io/pip/2.7/get-pip.py'
end

case node['platform']
when 'centos'
  include_recipe "swift::setup-centos"

when 'ubuntu'
  include_recipe "swift::setup-ubuntu"
end

case node['platform']
when 'ubuntu'
  execute "select default python version" do
    command "ln -sf #{default_python} /usr/bin/python"
  end
end

# it's a brave new world
bash 'install pip' do
  code <<-EOF
    set -o pipefail
    curl #{node['pip_url']} | #{default_python}
    EOF
  if not node['full_reprovision']
    not_if "which pip"
  end
end

# pip 8.0 is more or less broken on trusty -> https://github.com/pypa/pip/issues/3384
execute "upgrade pip" do
  command "#{default_pip} install --upgrade 'pip>=8.0.2'"
  default_env true
end

execute "fix pip warning 1" do
  command "sed '/env_reset/a Defaults\talways_set_home' -i /etc/sudoers"
  not_if "grep always_set_home /etc/sudoers"
  default_env true
end

execute "fix pip warning 2" do
  command "#{default_pip} install --upgrade ndg-httpsclient"
  default_env true
end

# install pip packages

[
  "s3cmd",
  "awscli-plugin-endpoint",
  "bandit==1.5.1",  # pin bandit to avoid pyyaml issues on bionic (at least)
].each do |pkg|
  execute "pip install #{pkg}" do
    command "#{default_pip} install #{pkg}"
    default_env true
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
  default_env true
end

[
  "/vagrant/.functions.sh",
].each do |filename|
  execute "source-#{filename}" do
    command "echo 'source #{filename}' >> #{profile_file}"
    not_if "grep 'source #{filename}' #{profile_file}"
    default_env true
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
    default_env true
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
  default_env true
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
    default_env true
  end
end
