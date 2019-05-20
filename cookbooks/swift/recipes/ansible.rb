# Copyright (c) 2019 SwiftStack, Inc.
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

[
  "ansible",
].each do |pkg|
  execute "pip install #{pkg}" do
    command "pip install #{pkg}"
  end
end

[
  "/etc/ansible",
  "/var/log/ansible",
].each do |dir|
  directory dir do
    owner node['username']
    group node["username"]
    action :create
  end
end

[
  'hosts',
  'ansible.cfg',
].each do |filename|
  cookbook_file "/etc/ansible/#{filename}" do
    source "etc/ansible/#{filename}"
    owner node["username"]
    group node["username"]
  end
end
