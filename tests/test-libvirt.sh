#!/bin/bash
set -ex
source localrc-template
export IP=192.168.58.8
export VAGRANT_DEFAULT_PROVIDER=libvirt
export LIBVIRT_DEFAULT_URI=qemu:///system
export SSL=true
export ENCRYPTION=true
export STATSD_EXPORTER=true

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
