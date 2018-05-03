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
include_recipe "losf::leveldb"

execute "go get levigo" do
  command "go get github.com/jmhodges/levigo"
  environment("CGO_CFLAGS" => "#{node['source_root']}/leveldb/include",
              "CGO_LDFLAGS" => "-L/usr/local/lib",
              "GOPATH" => "/vagrant/go")
  if not node['full_reprovision']
    creates "/home/#{node['username']}/src/github.com/jmhodges/levigo"
  end
end
