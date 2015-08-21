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

### Setup
execute "apt-get-update" do
  command "apt-get update"
  action :run
end

bash 'install mysql silently' do
  user "root"
  code <<-EOC
    sudo debconf-set-selections <<< 'mariadb-server-5.5 mysql-server/root_password password database_password'
    sudo debconf-set-selections <<< 'mariadb-server-5.5 mysql-server/root_password_again password database_password'
    apt-get install -y mariadb-server python-mysqldb
  EOC
  environment "DEBIAN_FRONTEND" =>'noninteractive'
  not_if "which mysql"
end

%w{
  keystone
  python-openstackclient
  }.each do |package_name|
  apt_package "#{package_name}" do
    action :install
  end
end

