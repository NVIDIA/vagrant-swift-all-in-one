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

include_recipe "losf::gopath"

# dependencies for protobuf's make process
package("autoconf") { action :install }
package("automake") { action :install }
package("libtool") { action :install }
package("curl") { action :install }
package("make") { action :install }
package("g++") { action :install }
package("unzip") { action :install }


execute "git protobuf" do
  cwd "#{node['source_root']}"
  command "git clone -b #{node['protobuf_repo_branch']} #{node['protobuf_repo']}"
  user node['username']
  group node["username"]
  creates "#{node['source_root']}/protobuf"
  action :run
end

execute "build and install protobuf" do
  cwd "#{node['source_root']}/protobuf"
  command "autoreconf && " \
          "./configure && " \
          "make && " \
          "sudo make install && " \
          "sudo ldconfig"
  if not node['full_reprovision']
    creates "/usr/local/bin/protoc"
  end
  # avoid /opt/chef/embedded/bin - related to chef/chef-dk#313
  # environment 'PATH' => "/usr/bin:#{ENV['PATH']}"
  action :run
end

execute "go get protoc-gen-go" do
  command "go get -u github.com/golang/protobuf/protoc-gen-go"
  environment({"GOPATH": "/vagrant/go"})
  if not node['full_reprovision']
    creates "/vagrant/go/src/github.com/golang/protobuf"
  end
end
