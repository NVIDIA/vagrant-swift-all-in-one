#!/bin/sh
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

echo "===> Start initial settings for swift function_test"
WORK_DIR="/vagrant/scripts"

# Prepare
apt-get install -y jq
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY

# Get Token
TOKEN=ADMIN

# Create Region(RegionOne)
REGION_ID="RegionOne"
sed -e s/@REGION_ID@/${REGION_ID}/g -e 's/@DESCRIPTION@/Region one/g' ${WORK_DIR}/region_template.json >${WORK_DIR}/regionone_region.json
curl -i -X POST http://127.0.0.1:5000/v3/regions -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json" -H "Accept: application/json" -T ${WORK_DIR}/regionone_region.json


# Create project (demo, admin, service)
sed -e s/@PROJECT_NAME@/demo/g -e s/@DOMAIN_ID@/default/g ${WORK_DIR}/project_template.json >${WORK_DIR}/demo_project.json
sed -e s/@PROJECT_NAME@/admin/g -e s/@DOMAIN_ID@/default/g ${WORK_DIR}/project_template.json >${WORK_DIR}/admin_project.json
sed -e s/@PROJECT_NAME@/service/g -e s/@DOMAIN_ID@/default/g ${WORK_DIR}/project_template.json >${WORK_DIR}/service_project.json

DEMO_PROJECT_ID=$(curl -sS -X POST http://127.0.0.1:5000/v3/projects -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json" -H "Accept: application/json" -T ${WORK_DIR}/demo_project.json | jq .project.id |tr -d '"')
ADMIN_PROJECT_ID=$(curl -sS -X POST http://127.0.0.1:5000/v3/projects -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json" -H "Accept: application/json" -T ${WORK_DIR}/admin_project.json | jq .project.id |tr -d '"')
SERVICE_PROJECT_ID=$(curl -sS -X POST http://127.0.0.1:5000/v3/projects -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json" -H "Accept: application/json" -T ${WORK_DIR}/service_project.json | jq .project.id |tr -d '"')

# Create User (demo, admin, swift)
sed -e s/@USER_NAME@/demo/g -e s/@PASSWORD@/demo/g -e s/@DOMAIN_ID@/default/g ${WORK_DIR}/user_template.json >${WORK_DIR}/demo_user.json
sed -e s/@USER_NAME@/admin/g -e s/@PASSWORD@/admin_password/g -e s/@DOMAIN_ID@/default/g ${WORK_DIR}/user_template.json >${WORK_DIR}/admin_user.json
sed -e s/@USER_NAME@/swift/g -e s/@PASSWORD@/swift_password/g -e s/@DOMAIN_ID@/default/g ${WORK_DIR}/user_template.json >${WORK_DIR}/swift_user.json

DEMO_ID=$(curl -sS -X POST http://127.0.0.1:35357/v3/users -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json" -H "Accept: application/json" -T ${WORK_DIR}/demo_user.json | jq .user.id |tr -d '"')
ADMIN_ID=$(curl -sS -X POST http://127.0.0.1:35357/v3/users -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json" -H "Accept: application/json" -T ${WORK_DIR}/admin_user.json | jq .user.id |tr -d '"')
SWIFT_ID=$(curl -sS -X POST http://127.0.0.1:35357/v3/users -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json" -H "Accept: application/json" -T ${WORK_DIR}/swift_user.json | jq .user.id |tr -d '"')

# Create Role (admin, _member_)
sed -e s/@ROLE_NAME@/admin/g ${WORK_DIR}/role_template.json >${WORK_DIR}/admin_role.json
sed -e 's/@ROLE_NAME@/_member_/g' ${WORK_DIR}/role_template.json >${WORK_DIR}/member_role.json
ADMIN_ROLE_ID=$(curl -sS -X POST http://127.0.0.1:5000/v3/roles -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json" -H "Accept: application/json" -T ${WORK_DIR}/admin_role.json | jq .role.id |tr -d '"')
MEMBER_ROLE_ID=$(curl -sS -X POST http://127.0.0.1:5000/v3/roles -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json" -H "Accept: application/json" -T ${WORK_DIR}/member_role.json | jq .role.id |tr -d '"')

############################
# Grant role to project user
#  admin  -> admin,_member_
#  swift -> admin,_member_
############################
curl -sS -X PUT http://127.0.0.1:35357/v3/projects/${ADMIN_PROJECT_ID}/users/${ADMIN_ID}/roles/${MEMBER_ROLE_ID} -H "X-Auth-Token: ${TOKEN}"
curl -sS -X PUT http://127.0.0.1:35357/v3/projects/${ADMIN_PROJECT_ID}/users/${ADMIN_ID}/roles/${ADMIN_ROLE_ID} -H "X-Auth-Token: ${TOKEN}"
curl -sS -X PUT http://127.0.0.1:35357/v3/projects/${SERVICE_PROJECT_ID}/users/${SWIFT_ID}/roles/${MEMBER_ROLE_ID} -H "X-Auth-Token: ${TOKEN}"
curl -sS -X PUT http://127.0.0.1:35357/v3/projects/${SERVICE_PROJECT_ID}/users/${SWIFT_ID}/roles/${ADMIN_ROLE_ID} -H "X-Auth-Token: ${TOKEN}"

############################
# Create Service
############################
sed -e s/@TYPE@/identity/g -e s/@NAME@/keystone/g -e 's/@DESCRIPTION@/OpenStack Identity/g' ${WORK_DIR}/service_template.json >${WORK_DIR}/service_keystone.json
sed -e 's/@TYPE@/object-store/g' -e s/@NAME@/swift/g -e 's/@DESCRIPTION@/OpenStack Object Storage/g' ${WORK_DIR}/service_template.json >${WORK_DIR}/service_swift.json

KEYSTONE_SERVICE_ID=`curl -sS -X POST http://127.0.0.1:35357/v3/services -T ${WORK_DIR}/service_keystone.json -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json" | jq .service.id |tr -d '"'`
SWIFT_SERVICE_ID=`curl -sS -X POST http://127.0.0.1:35357/v3/services -T ${WORK_DIR}/service_swift.json -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json"| jq .service.id |tr -d '"'`

############################
# Create endpoint list
############################
sed -e s/@INTERFACE@/admin/g -e 's/@NAME@/keystone/g' -e 's/@TYPE@/identity/g' -e "s/@REGION_ID@/${REGION_ID}/g" -e 's+@URL@+http://127.0.0.1:35357/v2.0+g' -e "s/@SERVICE_ID@/${KEYSTONE_SERVICE_ID}/g" ${WORK_DIR}/endpoint_template.json >${WORK_DIR}/ep_admin_keystone.json
sed -e s/@INTERFACE@/internal/g -e 's/@NAME@/keystone/g' -e 's/@TYPE@/identity/g' -e "s/@REGION_ID@/${REGION_ID}/g" -e 's+@URL@+http://127.0.0.1:35357/v2.0+g' -e "s/@SERVICE_ID@/${KEYSTONE_SERVICE_ID}/g" ${WORK_DIR}/endpoint_template.json >${WORK_DIR}/ep_public_keystone.json
sed -e s/@INTERFACE@/public/g -e 's/@NAME@/keystone/g' -e 's/@TYPE@/identity/g' -e "s/@REGION_ID@/${REGION_ID}/g" -e 's+@URL@+http://127.0.0.1:35357/v2.0+g' -e "s/@SERVICE_ID@/${KEYSTONE_SERVICE_ID}/g" ${WORK_DIR}/endpoint_template.json >${WORK_DIR}/ep_internal_keystone.json

curl -sS -X POST http://127.0.0.1:35357/v3/endpoints -T ${WORK_DIR}/ep_admin_keystone.json -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json"
curl -sS -X POST http://127.0.0.1:35357/v3/endpoints -T ${WORK_DIR}/ep_public_keystone.json -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json"
curl -sS -X POST http://127.0.0.1:35357/v3/endpoints -T ${WORK_DIR}/ep_internal_keystone.json -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json"

sed -e s/@INTERFACE@/admin/g -e 's/@NAME@/swift/g' -e 's/@TYPE@/object-store/g' -e "s/@REGION_ID@/${REGION_ID}/g" -e 's+@URL@+http://127.0.0.1:8080/v1/AUTH_%(tenant_id)s+g' -e "s/@SERVICE_ID@/${SWIFT_SERVICE_ID}/g" ${WORK_DIR}/endpoint_template.json >${WORK_DIR}/ep_admin_swift.json
sed -e s/@INTERFACE@/internal/g -e 's/@NAME@/swift/g' -e 's/@TYPE@/object-store/g' -e "s/@REGION_ID@/${REGION_ID}/g" -e 's+@URL@+http://127.0.0.1:8080/v1/AUTH_%(tenant_id)s+g' -e "s/@SERVICE_ID@/${SWIFT_SERVICE_ID}/g" ${WORK_DIR}/endpoint_template.json >${WORK_DIR}/ep_internal_swift.json
sed -e s/@INTERFACE@/public/g -e 's/@NAME@/swift/g' -e 's/@TYPE@/object-store/g' -e "s/@REGION_ID@/${REGION_ID}/g" -e 's+@URL@+http://127.0.0.1:8080/v1/AUTH_%(tenant_id)s+g' -e "s/@SERVICE_ID@/${SWIFT_SERVICE_ID}/g" ${WORK_DIR}/endpoint_template.json >${WORK_DIR}/ep_public_swift.json

curl -sS -X POST http://127.0.0.1:35357/v3/endpoints -T ${WORK_DIR}/ep_admin_swift.json -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json"
curl -sS -X POST http://127.0.0.1:35357/v3/endpoints -T ${WORK_DIR}/ep_public_swift.json -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json"
curl -sS -X POST http://127.0.0.1:35357/v3/endpoints -T ${WORK_DIR}/ep_internal_swift.json -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json"

# cleanup
rm -f ${WORK_DIR}/demo_project.json
rm -f ${WORK_DIR}/admin_project.json
rm -f ${WORK_DIR}/service_project.json
rm -f ${WORK_DIR}/demo_user.json
rm -f ${WORK_DIR}/admin_user.json
rm -f ${WORK_DIR}/swift_user.json
rm -f ${WORK_DIR}/admin_role.json
rm -f ${WORK_DIR}/member_role.json
rm -f ${WORK_DIR}/service_keystone.json
rm -f ${WORK_DIR}/service_swift.json
rm -f ${WORK_DIR}/regionone_region.json
rm -f ${WORK_DIR}/ep_admin_keystone.json
rm -f ${WORK_DIR}/ep_admin_swift.json
rm -f ${WORK_DIR}/ep_internal_keystone.json
rm -f ${WORK_DIR}/ep_internal_swift.json
rm -f ${WORK_DIR}/ep_public_keystone.json
rm -f ${WORK_DIR}/ep_public_swift.json

echo "===> Finish !!!"

