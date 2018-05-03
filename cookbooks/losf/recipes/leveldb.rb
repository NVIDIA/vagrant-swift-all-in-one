# Copyright (c) 2018 SwiftStack, Inc.
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
include_recipe "losf::cmake"
include_recipe "losf::snappy"


execute "git leveldb" do
  cwd "#{node['source_root']}"
  command "git clone -b #{node['leveldb_repo_branch']} #{node['leveldb_repo']}"
  user node['username']
  group node["username"]
  creates "#{node['source_root']}/leveldb"
  action :run
end

execute "build and install leveldb" do
  cwd "#{node['source_root']}/leveldb"
  command "cmake -DBUILD_SHARED_LIBS=yes && " \
          "make install &&" \
          "ldconfig"
  if not node['full_reprovision']
    creates "/usr/local/lib/libleveldb.so"
  end
  # avoid /opt/chef/embedded/bin - related to chef/chef-dk#313
  # environment 'PATH' => "/usr/bin:#{ENV['PATH']}"
  action :run
end
