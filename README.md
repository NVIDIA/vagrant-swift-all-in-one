vagrant-swift-all-in-one
========================

This project assumes you have Virtualbox and Vagrant.

A Swift-All-In-One in a few easy steps.

 1. `git submodule init`
 1. `git submodule update`
 1. `vagrant up`
 1. `vagrant ssh`
 1. `echo "awesome" > test`
 1. `swift upload test test`
 1. `swift download test test -o -`

localrc-template
========================

A few things are configurable, see `localrc-template`.

 1. `cp localrc-template localrc`
 1. `vi localrc`
 1. `source localrc`
 1. `vagrant provision`
 1. `vagrant ssh`
 1. `remakerings`
