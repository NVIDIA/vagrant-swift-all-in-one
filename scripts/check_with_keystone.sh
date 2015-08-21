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

# Prepare
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
WORK_DIR="/vagrant/scripts"
KEYSTONE_ADMIN_TOKEN=admin_token
ADMIN_PROJECT_ID=$(curl -sS -X GET http://127.0.0.1:35357/v3/projects?name=admin -H "X-Auth-Token: ${KEYSTONE_ADMIN_TOKEN}" | jq .projects[].id | tr -d '"')
TEST_PROJECT_ID=$(curl -sS -X GET http://127.0.0.1:35357/v3/projects?name=test -H "X-Auth-Token: ${KEYSTONE_ADMIN_TOKEN}" | jq .projects[].id | tr -d '"')
TEST2_PROJECT_ID=$(curl -sS -X GET http://127.0.0.1:35357/v3/projects?name=test2 -H "X-Auth-Token: ${KEYSTONE_ADMIN_TOKEN}" | jq .projects[].id | tr -d '"')
TEST3_PROJECT_ID=$(curl -sS -X GET http://127.0.0.1:35357/v3/projects?name=test3 -H "X-Auth-Token: ${KEYSTONE_ADMIN_TOKEN}" | jq .projects[].id | tr -d '"')
TEST4_PROJECT_ID=$(curl -sS -X GET http://127.0.0.1:35357/v3/projects?name=test4 -H "X-Auth-Token: ${KEYSTONE_ADMIN_TOKEN}" | jq .projects[].id | tr -d '"')
TEST5_PROJECT_ID=$(curl -sS -X GET http://127.0.0.1:35357/v3/projects?name=test5 -H "X-Auth-Token: ${KEYSTONE_ADMIN_TOKEN}" | jq .projects[].id | tr -d '"')

# Restart swift (To solved problem that keystonemiddleware is forwarding requests through proxy)
/vagrant/bin/resetswift
/vagrant/swift/doc/saio/bin/startmain

# Checking tester
sed -e s/@USER_NAME@/tester/g \
    -e s/@PASSWORD@/testing/g \
    -e s/@DOMAIN_NAME@/Default/g \
    -e s/@PROJECT_NAME@/test/g \
    ${WORK_DIR}/get_user_token_template.json >${WORK_DIR}/get_tester_token.json

export TOKEN=`curl -isS -X POST http://127.0.0.1:35357/v3/auth/tokens -H "Content-Type: application/json" -H "Accept: application/json" -T ${WORK_DIR}/get_tester_token.json | grep X-Subject-Token | sed -e "s/X-Subject-Token: //g"`
curl -isS -X PUT -H "X-Auth-Token: $TOKEN" http://127.0.0.1:8080/v1/AUTH_${TEST_PROJECT_ID}/test_container
curl -isS -X GET -H "X-Auth-Token: $TOKEN" http://127.0.0.1:8080/v1/AUTH_${TEST_PROJECT_ID}
curl -isS -X DELETE -H "X-Auth-Token: $TOKEN" http://127.0.0.1:8080/v1/AUTH_${TEST_PROJECT_ID}/test_container


# Checking tester2
sed -e s/@USER_NAME@/tester2/g \
    -e s/@PASSWORD@/testing2/g \
    -e s/@DOMAIN_NAME@/Default/g \
    -e s/@PROJECT_NAME@/test2/g \
    ${WORK_DIR}/get_user_token_template.json >${WORK_DIR}/get_tester2_token.json

export TOKEN=`curl -isS -X POST http://127.0.0.1:35357/v3/auth/tokens -H "Content-Type: application/json" -H "Accept: application/json" -T ${WORK_DIR}/get_tester2_token.json | grep X-Subject-Token | sed -e "s/X-Subject-Token: //g"`
curl -isS -X PUT -H "X-Auth-Token: $TOKEN" http://127.0.0.1:8080/v1/AUTH_${TEST2_PROJECT_ID}/test_container2
curl -isS -X GET -H "X-Auth-Token: $TOKEN" http://127.0.0.1:8080/v1/AUTH_${TEST2_PROJECT_ID}
curl -isS -X DELETE -H "X-Auth-Token: $TOKEN" http://127.0.0.1:8080/v1/AUTH_${TEST2_PROJECT_ID}/test_container2


# Checking tester3
sed -e s/@USER_NAME@/tester3/g \
    -e s/@PASSWORD@/testing3/g \
    -e s/@DOMAIN_NAME@/Default/g \
    -e s/@PROJECT_NAME@/test/g \
    ${WORK_DIR}/get_user_token_template.json >${WORK_DIR}/get_tester3_token.json

export TOKEN=`curl -isS -X POST http://127.0.0.1:35357/v3/auth/tokens -H "Content-Type: application/json" -H "Accept: application/json" -T ${WORK_DIR}/get_tester3_token.json | grep X-Subject-Token | sed -e "s/X-Subject-Token: //g"`
curl -isS -X PUT -H "X-Auth-Token: $TOKEN" http://127.0.0.1:8080/v1/AUTH_${TEST3_PROJECT_ID}/test_container3
echo "\n===> ^^^^^ Expect 403 Error, 403 is OK. ^^^^^"
curl -isS -X GET -H "X-Auth-Token: $TOKEN" http://127.0.0.1:8080/v1/AUTH_${TEST3_PROJECT_ID}
echo "\n===> ^^^^^ Expect 403 Error, 403 is OK. ^^^^^"
curl -isS -X DELETE -H "X-Auth-Token: $TOKEN" http://127.0.0.1:8080/v1/AUTH_${TEST3_PROJECT_ID}/test_container3
echo "\n===> ^^^^^ Expect 403 Error, 403 is OK. ^^^^^"


# Checking tester4
sed -e 's/@USER_NAME@/tester4/g' \
    -e 's/@PASSWORD@/testing4/g' \
    -e 's/@DOMAIN_NAME@/test-domain/g' \
    -e 's/@PROJECT_NAME@/test4/g' \
    ${WORK_DIR}/get_user_token_template.json >${WORK_DIR}/get_tester4_token.json

export TOKEN=`curl -isS -X POST http://127.0.0.1:35357/v3/auth/tokens -H "Content-Type: application/json" -H "Accept: application/json" -T ${WORK_DIR}/get_tester4_token.json | grep X-Subject-Token | sed -e "s/X-Subject-Token: //g"`
curl -isS -X PUT -H "X-Auth-Token: $TOKEN" http://127.0.0.1:8080/v1/AUTH_${TEST4_PROJECT_ID}/test_container4
curl -isS -X GET -H "X-Auth-Token: $TOKEN" http://127.0.0.1:8080/v1/AUTH_${TEST4_PROJECT_ID}
curl -isS -X DELETE -H "X-Auth-Token: $TOKEN" http://127.0.0.1:8080/v1/AUTH_${TEST4_PROJECT_ID}/test_container4


# Checking tester5
sed -e 's/@USER_NAME@/tester5/g' \
    -e 's/@PASSWORD@/testing5/g' \
    -e 's/@DOMAIN_NAME@/Default/g' \
    -e 's/@PROJECT_NAME@/test5/g' \
    ${WORK_DIR}/get_user_token_template.json >${WORK_DIR}/get_tester5_token.json


export TOKEN=`curl -isS -X POST http://127.0.0.1:35357/v3/auth/tokens -H "Content-Type: application/json" -H "Accept: application/json" -T ${WORK_DIR}/get_tester5_token.json | grep X-Subject-Token | sed -e "s/X-Subject-Token: //g"`
curl -isS -X PUT -H "X-Auth-Token: $TOKEN" http://127.0.0.1:8080/v1/AUTH_${TEST5_PROJECT_ID}/test_container4
echo "\n===> ^^^^^ Expect 403 Error, 403 is OK. ^^^^^"
curl -isS -X GET -H "X-Auth-Token: $TOKEN" http://127.0.0.1:8080/v1/AUTH_${TEST5_PROJECT_ID}
echo "\n===> ^^^^^ Expect 403 Error, 403 is OK. ^^^^^"
curl -isS -X DELETE -H "X-Auth-Token: $TOKEN" http://127.0.0.1:8080/v1/AUTH_${TEST5_PROJECT_ID}/test_container4
echo "\n===> ^^^^^ Expect 403 Error, 403 is OK. ^^^^^"

# Checking tester6
sed -e 's/@USER_NAME@/tester6/g' \
    -e 's/@PASSWORD@/testing6/g' \
    -e 's/@DOMAIN_NAME@/Default/g' \
    -e 's/@PROJECT_NAME@/test/g' \
    ${WORK_DIR}/get_user_token_template.json >${WORK_DIR}/get_tester6_token.json

export TOKEN=`curl -isS -X POST http://127.0.0.1:35357/v3/auth/tokens -H "Content-Type: application/json" -H "Accept: application/json" -T ${WORK_DIR}/get_tester6_token.json | grep X-Subject-Token | sed -e "s/X-Subject-Token: //g"`
curl -isS -X PUT -H "X-Auth-Token: $TOKEN" http://127.0.0.1:8080/v1/AUTH_${TEST_PROJECT_ID}/test_container6
curl -isS -X GET -H "X-Auth-Token: $TOKEN" http://127.0.0.1:8080/v1/AUTH_${TEST_PROJECT_ID}
curl -isS -X DELETE -H "X-Auth-Token: $TOKEN" http://127.0.0.1:8080/v1/AUTH_${TEST_PROJECT_ID}/test_container6

# clean
rm -f ${WORK_DIR}/get_tester_token.json
rm -f ${WORK_DIR}/get_tester2_token.json
rm -f ${WORK_DIR}/get_tester3_token.json
rm -f ${WORK_DIR}/get_tester4_token.json
rm -f ${WORK_DIR}/get_tester5_token.json
rm -f ${WORK_DIR}/get_tester6_token.json
