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

if node['keystone_register_data_method'] == 'curl' then
  cookbook_file '/tmp/register_keystone_initial_data.sh' do
    mode 0744
  end

  bash 'register swift initial data to keystone by curl' do
    user "root"
    code <<-EOC
      unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
      sh /tmp/register_keystone_initial_data.sh
      rm -f register_keystone_initial_data.sh
    EOC
  end
else
  bash 'register keystone initial data by openstack-client' do
    user "root"
    code <<-EOC
      unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY

      # TODO
      # According to Openstack Installation Guide, there is not necessary to
      # create demo project/user but there is a problem if there is no
      # demo project/user creation before admin project/user creation.
      # So I put them for workaround.
      openstack project create --description "Demo Project" demo
      openstack user create --password demo_password demo --email demo@example.com --project demo

      openstack project create --description "Admin Project" admin
      openstack user create --password admin_password admin --email admin@example.com --project admin
      openstack role create admin
      openstack role add --project admin --user admin admin
      openstack project create --description "Service Project" service
      openstack service create --type identity --description "OpenStack Identity" keystone
      openstack endpoint create --publicurl http://127.0.0.1:5000/v2.0  --internalurl http://127.0.0.1:5000/v2.0  --adminurl http://127.0.0.1:35357/v2.0  --region RegionOne keystone

    EOC
    environment "OS_TOKEN" =>'ADMIN', "OS_AUTH_URL" =>'http://127.0.0.1:35357/v2.0'
  end

  bash 'register swift initial data to keystone' do
    user "root"
    code <<-EOC
      unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
      openstack user create --password swift_password swift --email admin@example.com --project service
      openstack role add --project service --user swift admin
      openstack service create --type object-store --description "OpenStack Object Storage" swift
      openstack endpoint create --publicurl 'http://127.0.0.1:8080/v1/AUTH_%(tenant_id)s'  --internalurl 'http://127.0.0.1:8080/v1/AUTH_%(tenant_id)s'  --adminurl 'http://127.0.0.1:8080' --region RegionOne swift
    EOC
    environment "OS_TOKEN" =>'ADMIN', "OS_AUTH_URL" =>'http://127.0.0.1:35357/v2.0'
  end
end

