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

GO_VERSION = "1.7"
GO_TARBALL = "go#{GO_VERSION}.linux-amd64.tar.gz"

execute "download go" do
  cwd "/usr/local/"
  command "rm -fr go; wget https://storage.googleapis.com/golang/#{GO_TARBALL}"
  creates "/usr/local/#{GO_TARBALL}"
end

execute "inflate go" do
  cwd "/usr/local/"
  command "tar zxvf #{GO_TARBALL}"
  creates "/usr/local/go"
end

execute "install go" do
  command "ln -s /usr/local/go/bin/* /usr/local/bin || true"
end

# go workspace
{
  "GOPATH" => node['gopath'],
  "PATH" => "$GOPATH/bin:$PATH",
}.each do |var, value|
  execute "hummingbird-env-#{var}" do
    command "echo 'export #{var}=#{value}' >> /home/vagrant/.profile"
    not_if "grep '#{var}=#{value}' /home/vagrant/.profile"
    action :run
  end
end
