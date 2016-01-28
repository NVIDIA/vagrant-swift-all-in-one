# Copyright (c) 2015 Fujitsu, Inc.
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

execute "keystone-configuring" do
  command "cp #{node['source_root']}/keystone/etc/keystone.conf.sample #{node['source_root']}/keystone/etc/keystone.conf"
  not_if { File.exists?("#{node['source_root']}/keystone/etc/keystone.conf")}
end

bash 'set_cron' do
  user "root"
  code <<-EOC
    (crontab -l -u keystone 2>&1 | grep -q token_flush) || echo '@hourly /usr/bin/keystone-manage token_flush >/var/log/keystone/keystone-tokenflush.log 2>&1' /var/spool/cron/crontabs/keystone
  EOC
  not_if "grep '@hourly' /var/spool/cron/crontabs/keystone"
end

execute "keystone-start" do
  command "/usr/local/bin/keystone-all --config-file #{node['source_root']}/keystone/etc/keystone.conf &"
  only_if { File.exists?("#{node['source_root']}/keystone/etc/keystone.conf")}
end

execute "populate_identity_service" do
  command '/usr/local/bin/keystone-manage db_sync'
  only_if { File.exists?("#{node['source_root']}/keystone/etc/keystone.conf")}
end
