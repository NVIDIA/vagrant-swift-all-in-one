vagrant-swift-all-in-one
========================

A virtualization toolchain for building an [OpenStack Swift-All-In-One](https://docs.openstack.org/swift/latest/development_saio.html).

This project relies on [vagrant](http://www.vagrantup.com/downloads.html),
you'll need to install vagrant and setup one of the supported virtualization
providers:

| Provider                           | Host OS       | Arch  |
| ---------------------------------- | ------------- | ----- |
| [VirtualBox](README-vbox.md)       | Linux         | amd64 |
| [libvirt](README-libvirt.md)       | Linux         | amd64 |
| [VMware](README-vmware.md)         | Mac           | arm   |
| [VMware](README-vmware-linux.md)   | Linux         | amd64 |
| [Parallels](README-parallels.md)   | Mac           | arm   |

localrc-template
================

Most providers will recommend you set some environ vars via your `localrc`

 1. `cp localrc-template localrc`
 1. `vi localrc`

Additionally chef provisioning exposes some optional configuration for the vm,
see `localrc-template`.

 1. `source localrc`
 1. `vagrant provision`
 1. `vagrant ssh`
 1. `rebuildswift`

running-tests
=============

You should be able to run most tests without too much fuss once SSH'ed into the
VM.

 1. `.unittests`
 1. `.functests`
 1. `.probetests`
 1. `vtox -e pep8`
 1. `vtox -e py38`
 1. `vtox  # run all gate checks`

s3cmd
=====

You know you want to play with s3api, we got you covered.

```
vagrant ssh
s3cmd mb s3://s3test
s3cmd ls
```

configure statsd_exporter/prometheus metrics
============================================

You should be able to optionally configure statsd_exporter/prometheus metrics for the Swift stack on the VM.

```
cp localrc-template localrc
sed -i 's/^\(export STATSD_EXPORTER=\)\([^ ]*\) /\1true/g' localrc
source localrc
vagrant provision
```

These will expose /metrics endpoints on ports 9100-9105 which you can check directly, and configure prometheus to scrape these endpoints every 10s and retain data for up to a day; you can then create ad-hoc graphs at

 * http://saio:9090/graph


ninja-dev-tricks
================

You should add the configured `IP` from your localrc to your `/etc/hosts` or use the default:

```
sudo bash -c 'echo "192.168.8.80    saio" >> /etc/hosts'
```

Then you can easily share snippets that talk to network services running in your Swift-All-In-One from your host!

```
curl -s http://saio:8080/info | python -m json.tool
```

A few scripts are available to make your dev life easier.

 1. `vagrant up --provision` will bring up your VM in working order (useful
    when your VM is halted)
 1. `source localrc; vagrant provision` on your host to push the new Chef bits
    in place (useful if you change localrc)
 1. `rebuildswift` to reapply everything like it would be at the end of Chef
    time (useful to revert local config changes)
 1. `resetswift` will wipe the drives and leave any local config changes in
    place (useful just to clean out Swift data)
 1. `reinstallswift` will make sure all of the bin scripts are installed
    correctly and restart the main swift processes (useful if you change
    branches)
 1. `autodoc [swift|swiftclient]` will build the sphinx docs and
    watch files for changes, and upload them to a public container on your vm
    so you can review them as you edit
 1. `vtox` will hack the local tox.ini and setup.py so you can run tox tests
    successfully on the swift repo in the `/vagrant` directory
 1. `reec` will rebuild/reinstall all the liberasure/pyeclib[/isa-l] bits!
 1. `venv py37` will make sure your tox virtualenv is ready and let you py3
