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
  command "rm /home/vagrant/postinstall.sh || true"
end

# deadsnakes for py2.6
execute "deadsnakes key" do
  command "sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys DB82666C"
  action :run
  not_if "sudo apt-key list | grep 'Launchpad Old Python Versions'"
end

cookbook_file "/etc/apt/sources.list.d/fkrull-deadsnakes-precise.list" do
  source "etc/apt/sources.list.d/fkrull-deadsnakes-precise.list"
  mode 0644
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
  "curl", "gcc", "memcached", "rsync", "sqlite3", "xfsprogs", "git-core",
  "build-essential", "python-dev", "libffi-dev", "python-setuptools",
  "python-coverage", "python-dev", "python-nose", "python-simplejson",
  "python-xattr", "python-eventlet", "python-greenlet", "python-pastedeploy",
  "python-netifaces", "python-pip", "python-dnspython", "python-mock",
  "python3.3", "python3.3-dev", "python3.4", "python3.4-dev",
  "python2.6", "python2.6-dev", "libxml2-dev", "libxml2", "libxslt1-dev",
]
extra_packages = node['extra_packages']
(required_packages + extra_packages).each do |pkg|
  package pkg do
    action :install
  end
end

execute "pip install -U pip"

# setup environment

execute "update-path" do
  command "echo 'export PATH=/vagrant/bin:$PATH' >> /home/vagrant/.profile"
  not_if "grep /vagrant/bin /home/vagrant/.profile"
  action :run
end

# swift command line env setup

{
  "ST_AUTH" => "http://#{node['hostname']}:8080/auth/v1.0",
  "ST_USER" => "test:tester",
  "ST_KEY" => "testing",
}.each do |var, value|
  execute "swift-env-#{var}" do
    command "echo 'export #{var}=#{value}' >> /home/vagrant/.profile"
    not_if "grep #{var} /home/vagrant/.profile"
    action :run
  end
end

# other useful env vars

{
  "NOSE_INCLUDE_EXE" => "true",
}.each do |var, value|
  execute "swift-env-#{var}" do
    command "echo 'export #{var}=#{value}' >> /home/vagrant/.profile"
    not_if "grep #{var} /home/vagrant/.profile"
    action :run
  end
end
