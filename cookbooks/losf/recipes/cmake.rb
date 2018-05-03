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


if node["platform"] == "ubuntu" && node["platform_version"] >= "18.04" then
  # Ubuntu 18.04 ships with a new enough cmake for leveldb
  package "cmake" do
    action :install
  end
else
  # Ubuntu 16.04 and below ship with an old cmake that leveldb won't build with
  execute "git cmake" do
    cwd "#{node['source_root']}"
    command "git clone -b #{node['cmake_repo_branch']} #{node['cmake_repo']}"
    user node['username']
    group node["username"]
    creates "#{node['source_root']}/cmake"
    action :run
  end

  execute "build and install cmake" do
    cwd "#{node['source_root']}/cmake"
    command "./configure && " \
      "make && " \
      "make install"
    if not node['full_reprovision']
      creates "/usr/local/bin/cmake"
    end
    # avoid /opt/chef/embedded/bin - related to chef/chef-dk#313
    # environment 'PATH' => "/usr/bin:#{ENV['PATH']}"
    action :run
  end
end
