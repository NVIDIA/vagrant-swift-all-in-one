# Copyright (c) 2020 SwiftStack, Inc.
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

if not node['zipkin'] then
  # TODO: more cleanup?
  service 'zipkin-server' do
    action [:disable, :stop]
  end
  return
end

JAR_DIR = "/usr/local/share/java"
directory JAR_DIR do
  user node['username']
  group node["username"]
  action :create
end

LATEST_URL = "https://search.maven.org/remote_content?g=io.zipkin&a=zipkin-server&v=LATEST&c=exec"
execute "get zipkin-server jar" do
  cwd JAR_DIR
  user node['username']
  group node["username"]
  command "curl -O $( curl -si '#{LATEST_URL}' | sed -e '/^location:/!d;s/^location: *//i;s/\r//' ) && " \
    "rm -f zipkin-server.jar && " \
    "ln -s $(ls zipkin-server*.jar | sort -V  |tail -n 1) zipkin-server.jar"
  if not node['full_reprovision']
    creates "#{JAR_DIR}/zipkin-server.jar"
  end
end


# systemd unit file

cookbook_file "/etc/systemd/system/zipkin-server.service" do
  source "etc/systemd/system/zipkin-server.service"
end

service 'zipkin-server' do
  action [:enable, :restart, :start]
end
