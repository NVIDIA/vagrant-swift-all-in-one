vagrant-swift-all-in-one
========================

A Swift-All-In-One in a few easy steps.

 1. `vagrant up`
    - This may fail like
      ```
      The IP address configured for the host-only network is not within the
      allowed ranges. Please update the address used to be within the allowed
      ranges and run the command again.

        Address: 192.168.8.80
        Ranges: 192.168.56.0/21

      Valid ranges can be modified in the /etc/vbox/networks.conf file. For
      more information including valid format see:

        https://www.virtualbox.org/manual/ch06.html#network_hostonly
      ```
    - You can fix this by ensuring `/etc/vbox/networks.conf` exists and updating
      it appropriately:
      ```
      sudo mkdir -p /etc/vbox
      echo "* 192.168.8.0/24" | sudo tee -a /etc/vbox/networks.conf
      ```
 1. `vagrant ssh`
 1. `echo "awesome" > test`
 1. `swift upload test test`
 1. `swift download test test -o -`

This project assumes you have Virtualbox and Vagrant.

 * https://www.virtualbox.org/wiki/Downloads
 * http://www.vagrantup.com/downloads.html

running-tests
=============

You should be able to run most tests without too much fuss once SSH'ed into the
VM.

 1. `.unittests`
 1. `.functests`
 1. `.probetests`
 1. `vtox -e pep8`
 1. `vtox -e py27`
 1. `vtox  # run all gate checks`

localrc-template
================

A few things are configurable, see `localrc-template`.

 1. `cp localrc-template localrc`
 1. `vi localrc`
 1. `source localrc`
 1. `vagrant provision`
 1. `vagrant ssh`
 1. `rebuildswift`


s3cmd
=====

You know you want to play with s3api, we got you covered.

```
vagrant ssh
s3cmd mb s3://s3test
s3cmd ls
```

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
