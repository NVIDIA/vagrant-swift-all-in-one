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

cookbook_file '/etc/mysql/my.cnf' do
  source "/etc/mysql/my.cnf"
  owner "vagrant"
  group "vagrant"
end

cookbook_file "/tmp/set_keystone_db.sql" do
  source "set_keystone_db.sql"
  owner "vagrant"
  group "vagrant"
end

bash 'setting database' do
  user "root"
  code <<-EOC
    mysql -u root -pdatabase_password < /tmp/set_keystone_db.sql
  EOC
  not_if "mysqlshow -u root -pdatabase_password |grep keystone"
end

cookbook_file '/etc/keystone/keystone.conf' do
  source "/etc/keystone/keystone.conf"
  owner "vagrant"
  group "vagrant"
end

bash 'disable_sqlite_db' do
  user "root"
  code <<-EOC
    rm -f /var/lib/keystone/keystone.db
  EOC
  only_if { File.exists?("/var/lib/keystone/keystone.db") }
end

bash 'set_cron' do
  user "root"
  code <<-EOC
    (crontab -l -u keystone 2>&1 | grep -q token_flush) || echo '@hourly /usr/bin/keystone-manage token_flush >/var/log/keystone/keystone-tokenflush.log 2>&1' /var/spool/cron/crontabs/keystone
  EOC
  not_if "grep '@hourly' /var/spool/cron/crontabs/keystone"
end

service 'mysql' do
  action [ :nothing]
  subscribes :restart, "cookbook_file[/etc/mysql/my.cnf]", :immediately
end

execute "populate_identity_service" do
  command 'su -s /bin/sh -c "keystone-manage db_sync" keystone'
  action :nothing
  subscribes :run, "cookbook_file[/etc/keystone/keystone.conf]", :immediately
end

service 'keystone' do
  action [ :nothing]
  subscribes :restart, "cookbook_file[/etc/keystone/keystone.conf]", :immediately
end

