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
TOKEN=admin_token

# Create domain (test-domain)
sed -e s/@DOMAIN_NAME@/test-domain/g ${WORK_DIR}/domain_template.json >${WORK_DIR}/test_domain.json
TEST_DOMAIN_ID="$(curl -sS -X POST http://127.0.0.1:5000/v3/domains -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json" -H "Accept: application/json" -T ${WORK_DIR}/test_domain.json |jq .domain.id |tr -d '"')"

# Create project (test, test2, test4, test5)
sed -e s/@PROJECT_NAME@/test/g -e s/@DOMAIN_ID@/default/g ${WORK_DIR}/project_template.json >${WORK_DIR}/test_project.json
sed -e s/@PROJECT_NAME@/test2/g -e s/@DOMAIN_ID@/default/g ${WORK_DIR}/project_template.json >${WORK_DIR}/test2_project.json
sed -e s/@PROJECT_NAME@/test4/g -e s/@DOMAIN_ID@/${TEST_DOMAIN_ID}/g ${WORK_DIR}/project_template.json >${WORK_DIR}/test4_project.json
sed -e s/@PROJECT_NAME@/test5/g -e s/@DOMAIN_ID@/default/g ${WORK_DIR}/project_template.json > ${WORK_DIR}/test5_project.json

TEST_PROJECT_ID=$(curl -sS -X POST http://127.0.0.1:5000/v3/projects -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json" -H "Accept: application/json" -T ${WORK_DIR}/test_project.json | jq .project.id |tr -d '"')
TEST2_PROJECT_ID=$(curl -sS -X POST http://127.0.0.1:5000/v3/projects -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json" -H "Accept: application/json" -T ${WORK_DIR}/test2_project.json | jq .project.id |tr -d '"')
TEST4_PROJECT_ID=$(curl -sS -X POST http://127.0.0.1:5000/v3/projects -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json" -H "Accept: application/json" -T ${WORK_DIR}/test4_project.json | jq .project.id |tr -d '"')
TEST5_PROJECT_ID=$(curl -sS -X POST http://127.0.0.1:5000/v3/projects -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json" -H "Accept: application/json" -T ${WORK_DIR}/test5_project.json | jq .project.id |tr -d '"')

# Create User (tester tester2 tester3 tester4 tester5 tester6)
sed -e s/@USER_NAME@/tester/g -e s/@PASSWORD@/testing/g -e s/@DOMAIN_ID@/default/g ${WORK_DIR}/user_template.json >${WORK_DIR}/tester_user.json
sed -e s/@USER_NAME@/tester2/g -e s/@PASSWORD@/testing2/g -e s/@DOMAIN_ID@/default/g ${WORK_DIR}/user_template.json >${WORK_DIR}/tester2_user.json
sed -e s/@USER_NAME@/tester3/g -e s/@PASSWORD@/testing3/g -e s/@DOMAIN_ID@/default/g ${WORK_DIR}/user_template.json >${WORK_DIR}/tester3_user.json
sed -e s/@USER_NAME@/tester4/g -e s/@PASSWORD@/testing4/g -e s/@DOMAIN_ID@/${TEST_DOMAIN_ID}/g ${WORK_DIR}/user_template.json >${WORK_DIR}/tester4_user.json
sed -e s/@USER_NAME@/tester5/g -e s/@PASSWORD@/testing5/g -e s/@DOMAIN_ID@/default/g ${WORK_DIR}/user_template.json >${WORK_DIR}/tester5_user.json
sed -e s/@USER_NAME@/tester6/g -e s/@PASSWORD@/testing6/g -e s/@DOMAIN_ID@/default/g ${WORK_DIR}/user_template.json >${WORK_DIR}/tester6_user.json

TESTER_ID=$(curl -sS -X POST http://127.0.0.1:35357/v3/users -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json" -H "Accept: application/json" -T ${WORK_DIR}/tester_user.json | jq .user.id |tr -d '"')
TESTER2_ID=$(curl -sS -X POST http://127.0.0.1:35357/v3/users -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json" -H "Accept: application/json" -T ${WORK_DIR}/tester2_user.json | jq .user.id |tr -d '"')
TESTER3_ID=$(curl -sS -X POST http://127.0.0.1:35357/v3/users -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json" -H "Accept: application/json" -T ${WORK_DIR}/tester3_user.json | jq .user.id |tr -d '"')
TESTER4_ID=$(curl -sS -X POST http://127.0.0.1:35357/v3/users -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json" -H "Accept: application/json" -T ${WORK_DIR}/tester4_user.json | jq .user.id |tr -d '"')
TESTER5_ID=$(curl -sS -X POST http://127.0.0.1:35357/v3/users -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json" -H "Accept: application/json" -T ${WORK_DIR}/tester5_user.json | jq .user.id |tr -d '"')
TESTER6_ID=$(curl -sS -X POST http://127.0.0.1:35357/v3/users -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json" -H "Accept: application/json" -T ${WORK_DIR}/tester6_user.json | jq .user.id |tr -d '"')


# Create Role (ResellerAdmin)
ADMIN_ROLE_ID=$(curl -sS -X GET http://127.0.0.1:5000/v3/roles?name=admin -H "X-Auth-Token: ${TOKEN}" -H "Accept: application/json"| jq .roles[].id | tr -d '"')
MEMBER_ROLE_ID=$(curl -sS -X GET http://127.0.0.1:5000/v3/roles?name=_member_ -H "X-Auth-Token: ${TOKEN}" -H "Accept: application/json"| jq .roles[].id | tr -d '"')

sed -e s/@ROLE_NAME@/service/g ${WORK_DIR}/role_template.json >${WORK_DIR}/service_role.json
sed -e s/@ROLE_NAME@/ResellerAdmin/g ${WORK_DIR}/role_template.json >${WORK_DIR}/reselleradmin_role.json

SERVICE_ROLE_ID=$(curl -sS -X POST http://127.0.0.1:5000/v3/roles -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json" -H "Accept: application/json" -T ${WORK_DIR}/service_role.json | jq .role.id |tr -d '"')
RESELLER_ADMIN_ROLE_ID=$(curl -sS -X POST http://127.0.0.1:5000/v3/roles -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json" -H "Accept: application/json" -T ${WORK_DIR}/reselleradmin_role.json | jq .role.id |tr -d '"')


############################
# Grant role to domain user
#  default::tester      -> admin
#  default::tester2     -> admin
#  default::tester3     -> _member_
#  test-domain::tester4 -> admin
#  default::tester5     -> service
#  default::tester6     -> ResellerAdmin
############################
curl -i -X PUT http://127.0.0.1:35357/v3/domains/default/users/${TESTER_ID}/roles/${ADMIN_ROLE_ID} -H "X-Auth-Token: ${TOKEN}"
curl -i -X PUT http://127.0.0.1:35357/v3/domains/default/users/${TESTER2_ID}/roles/${ADMIN_ROLE_ID} -H "X-Auth-Token: ${TOKEN}"
curl -i -X PUT http://127.0.0.1:35357/v3/domains/default/users/${TESTER3_ID}/roles/${MEMBER_ROLE_ID} -H "X-Auth-Token: ${TOKEN}"
curl -i -X PUT http://127.0.0.1:35357/v3/domains/${TEST_DOMAIN_ID}/users/${TESTER4_ID}/roles/${ADMIN_ROLE_ID} -H "X-Auth-Token: ${TOKEN}"
curl -i -X PUT http://127.0.0.1:35357/v3/domains/default/users/${TESTER5_ID}/roles/${SERVICE_ROLE_ID} -H "X-Auth-Token: ${TOKEN}"
curl -i -X PUT http://127.0.0.1:35357/v3/domains/default/users/${TESTER6_ID}/roles/${RESELLER_ADMIN_ROLE_ID} -H "X-Auth-Token: ${TOKEN}"


############################
# Grant role to project user
#  tester  -> admin
#  tester2 -> admin
#  tester3 -> _member_
#  tester4 -> admin
#  tester5 -> service
#  tester6 -> ResellerAdmin
############################
curl -sS -X PUT http://127.0.0.1:35357/v3/projects/${TEST_PROJECT_ID}/users/${TESTER_ID}/roles/${ADMIN_ROLE_ID} -H "X-Auth-Token: ${TOKEN}"
curl -sS -X PUT http://127.0.0.1:35357/v3/projects/${TEST2_PROJECT_ID}/users/${TESTER2_ID}/roles/${ADMIN_ROLE_ID} -H "X-Auth-Token: ${TOKEN}"
curl -sS -X PUT http://127.0.0.1:35357/v3/projects/${TEST_PROJECT_ID}/users/${TESTER3_ID}/roles/${MEMBER_ROLE_ID} -H "X-Auth-Token: ${TOKEN}"
curl -sS -X PUT http://127.0.0.1:35357/v3/projects/${TEST4_PROJECT_ID}/users/${TESTER4_ID}/roles/${ADMIN_ROLE_ID} -H "X-Auth-Token: ${TOKEN}"
curl -sS -X PUT http://127.0.0.1:35357/v3/projects/${TEST5_PROJECT_ID}/users/${TESTER5_ID}/roles/${SERVICE_ROLE_ID} -H "X-Auth-Token: ${TOKEN}"
curl -sS -X PUT http://127.0.0.1:35357/v3/projects/${TEST_PROJECT_ID}/users/${TESTER6_ID}/roles/${RESELLER_ADMIN_ROLE_ID} -H "X-Auth-Token: ${TOKEN}"

# cleanup
rm -f ${WORK_DIR}/test_domain.json
rm -f ${WORK_DIR}/test_project.json
rm -f ${WORK_DIR}/test2_project.json
rm -f ${WORK_DIR}/test4_project.json
rm -f ${WORK_DIR}/test5_project.json
rm -f ${WORK_DIR}/tester_user.json
rm -f ${WORK_DIR}/tester2_user.json
rm -f ${WORK_DIR}/tester3_user.json
rm -f ${WORK_DIR}/tester4_user.json
rm -f ${WORK_DIR}/tester5_user.json
rm -f ${WORK_DIR}/tester6_user.json
rm -f ${WORK_DIR}/service_role.json
rm -f ${WORK_DIR}/reselleradmin_role.json

sh ${WORK_DIR}/check_keystone_data.sh >${WORK_DIR}/check_keystone_data.log

echo "===> Finish !!!"

