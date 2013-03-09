vagrant-swift-saio
==================

A Swift-All-In-One in a few easy steps.

 1. `git submodule init`
 1. `git submodule update`
 1. `vagrant up saio`
 1. `vagrant ssh saio`
 1. `sudo chmod +r /home/swift/.swiftrc`  # doh!
 1. `sudo su - swift`
 1. `source .swiftrc`
 1. `swift stat -v`

There's a number of things in this recipe that differ from a "stock"
swift-all-in-one.  The difference is less pronounced if you su to swift, but I
think there'd be some work before it could drop in as a replacement dev
machine for standard dev workflow (e.g. resetswift/probetests).  There's also
quite a few things in the chef bits that could be tuned toward a vagrant work
flow if we don't mind specializing the recipes - particularlly the ability to
use a the vagrant share for the source code, so you don't have got setup
commit access from the vagrant vm everytime you re-up it.
