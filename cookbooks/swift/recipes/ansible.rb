#
#Copyright (c) 2015-2021, NVIDIA CORPORATION.
#SPDX-License-Identifier: Apache-2.0

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
