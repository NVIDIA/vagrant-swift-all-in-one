#!/bin/bash
set -ex
source localrc-template
export VAGRANT_DEFAULT_PROVIDER=vmware_desktop
export SSL=true
export ENCRYPTION=true
export STATSD_EXPORTER=true

# When testing with box
# 'bento/ubuntu-22.04' (v202502.21.0) for 'vmware_desktop (amd64)'
# I get an error on bring up
#     Warning: Authentication failure. Retrying...
# I assume the box is built wrong and some other 22.04 image might work?

vagrant destroy -f
VAGRANT_BOX=bento/ubuntu-24.04 vagrant up
# unittests work
vagrant ssh -c '.unittests'
# functtests only work if you downgarde boto, that's just how swift is right now
vagrant ssh -c 'sudo pip install "boto3<1.36" awscli s3transfer --upgrade'
vagrant ssh -c '.functests'
# you can go as low as 3.7
# vagrant ssh -c 'vtox -e py37'
# stock py3 works fine
vagrant ssh -c 'vtox -e py3'
# you can reinstall and swift still works
vagrant ssh -c "reinstallswift && .functests"
# new python is also available
vagrant ssh -c 'vtox -e py313'
