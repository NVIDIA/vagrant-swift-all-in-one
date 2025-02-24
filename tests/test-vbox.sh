#!/bin/bash
set -ex
source localrc-template
export VAGRANT_DEFAULT_PROVIDER=virtualbox
export SSL=true
export ENCRYPTION=true
export STATSD_EXPORTER=true

# TEST FOCAL
vagrant destroy -f
VAGRANT_BOX=bento/ubuntu-20.04 vagrant up
# unittests work
vagrant ssh -c '.unittests'
# functtests only work if you downgarde boto, that's just how swift is right now
vagrant ssh -c 'sudo pip install "boto3<1.36" awscli s3transfer --upgrade'
vagrant ssh -c '.functests'
# focal has old py36 you can use!
vagrant ssh -c 'vtox -e py36'
# unfortunately stock py3 tox is expected fail
vagrant ssh -c 'vtox -e py3; if [ $? -eq 0 ]; then exit 1 else; exit 0; fi'
# you can work around it tho!?
vagrant ssh -c 'TOX_CONSTRAINTS_FILE=/vagrant/swift/py3-constraints.txt vtox -e py3'
# magic tox constraints make py38 work tho!?
vagrant ssh -c 'vtox -e py38'
# you can reinstall and swift still works
vagrant ssh -c "reinstallswift && .functests"
# focal even has new py3.13!?
vagrant ssh -c 'vtox -e py313'
# TEST JAMMY & NOBLE
for box in 22.04 24.04; do
  vagrant destroy -f
  VAGRANT_BOX=bento/ubuntu-$box vagrant up
  # unittests work
  vagrant ssh -c '.unittests'
  # functtests only work if you downgarde boto, that's just how swift is right now
  vagrant ssh -c 'sudo pip install "boto3<1.36" awscli s3transfer --upgrade'
  vagrant ssh -c '.functests'
  # you can go as low as 3.7
  vagrant ssh -c 'vtox -e py37'
  # stock py3 works fine
  vagrant ssh -c 'vtox -e py3'
  # you can reinstall and swift still works
  vagrant ssh -c "reinstallswift && .functests"
  # new python is also available
  vagrant ssh -c 'vtox -e py313'
done
