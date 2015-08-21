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
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
WORK_DIR="/vagrant/scripts"

# Get Token
export TOKEN=admin_token

echo "===> Checking Services"
curl -sS -X GET http://127.0.0.1:35357/v3/services -H "X-Auth-Token: ${TOKEN}" | jq .

echo "===> Checking Endpoints"
curl -sS -X GET http://127.0.0.1:35357/v3/endpoints -H "X-Auth-Token: ${TOKEN}" | jq .

echo "===> Checking Domains"
curl -sS -X GET http://127.0.0.1:35357/v3/domains -H "X-Auth-Token: ${TOKEN}" | jq .

echo "===> Checking Projects"
curl -sS -X GET http://127.0.0.1:35357/v3/projects -H "X-Auth-Token: ${TOKEN}" | jq .

echo "===> Checking Users"
curl -sS -X GET http://127.0.0.1:35357/v3/users -H "X-Auth-Token: ${TOKEN}" | jq .

echo "===> Checking Roles"
curl -sS -X GET http://127.0.0.1:35357/v3/roles -H "X-Auth-Token: ${TOKEN}" | jq .

echo "===> Checking Role admin that tester is assigned"
echo "===> admin role assiged user id."
ADMIN_ROLE_ID=$(curl -sS -X GET http://127.0.0.1:35357/v3/roles?name=admin -H "X-Auth-Token: ${TOKEN}" -H "Accept: application/json"| jq .roles[].id | tr -d '"')
ACTUAL_ADMIN_ROLE_USER_IDS=$(curl -sS -X GET http://127.0.0.1:35357/v3/role_assignments?role.id=${ADMIN_ROLE_ID} -H "X-Auth-Token: ${TOKEN}"| jq .role_assignments[].user.id |tr -d '"')
echo ${ACTUAL_ADMIN_ROLE_USER_IDS}

echo "===> _member_ role assiged user id."
MEMBER_ROLE_ID=$(curl -sS -X GET http://127.0.0.1:35357/v3/roles?name=_member_ -H "X-Auth-Token: ${TOKEN}" -H "Accept: application/json"| jq .roles[].id | tr -d '"')
ACTUAL_MEMBER_ROLE_USER_IDS=$(curl -sS -X GET http://127.0.0.1:35357/v3/role_assignments?role.id=${MEMBER_ROLE_ID} -H "X-Auth-Token: ${TOKEN}"| jq .role_assignments[].user.id |tr -d '"')
echo ${ACTUAL_MEMBER_ROLE_USER_IDS}

echo "===> service role assiged user id."
SERVICE_ROLE_ID=$(curl -sS -X GET http://127.0.0.1:35357/v3/roles?name=service -H "X-Auth-Token: ${TOKEN}" -H "Accept: application/json"| jq .roles[].id | tr -d '"')
ACTUAL_SERVICE_ROLE_USER_IDS=$(curl -sS -X GET http://127.0.0.1:35357/v3/role_assignments?role.id=${SERVICE_ROLE_ID} -H "X-Auth-Token: ${TOKEN}"| jq .role_assignments[].user.id |tr -d '"')
echo ${ACTUAL_SERVICE_ROLE_USER_IDS}

echo "===> ResellerAdmin role assiged user id."
RESELLER_ADMIN_ROLE_ID=$(curl -sS -X GET http://127.0.0.1:35357/v3/roles?name=ResellerAdmin -H "X-Auth-Token: ${TOKEN}" -H "Accept: application/json"| jq .roles[].id | tr -d '"')
ACTUAL_RESELLER_ADMIN_ROLE_USER_IDS=$(curl -sS -X GET http://127.0.0.1:35357/v3/role_assignments?role.id=${RESELLER_ADMIN_ROLE_ID} -H "X-Auth-Token: ${TOKEN}"| jq .role_assignments[].user.id |tr -d '"')
echo ${ACTUAL_RESELLER_ADMIN_ROLE_USER_IDS}
