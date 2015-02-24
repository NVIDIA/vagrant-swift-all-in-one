vagrant-swift-all-in-one
========================

A Swift-All-In-One in a few easy steps.

 1. `vagrant up`
 1. `vagrant ssh`
 1. `echo "awesome" > test`
 1. `swift upload test test`
 1. `swift download test test -o -`

This project assumes you have Virtualbox and Vagrant.

 * https://www.virtualbox.org/wiki/Downloads
 * http://www.vagrantup.com/downloads.html

running-tests
=============

You should be able to run most tests without too much fuss.

 1. `.unittests`
 1. `.functests`
 1. `.probetests`
 1. `vtox -e pep8`
 1. `vtox -e py27`
 1. `vtox -e py26`
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

other things you may need to run, and when
===========================================
 1. if you've changed your localconf, then `vagrant provision` on the host to reconfigure swift
 2. if you've halted your VM, you'll need to `vagrant up --provision` on the host
 2. if you need to revert manual changes to swift's configuration, then `rebuildswift`
 3. if you need to just erase data in swift, then `resetswift`
 4. if you just changed branches you need to `reinstallswift`
