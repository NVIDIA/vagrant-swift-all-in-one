vagrant-swift-saio
==================

A Swift-All-In-One in 10 easy steps.

 1. `git submodule init`
 2. `git submodule update`
 3. `cd swift-solo`
 4. `curl -s https://github.com/orion/swift-solo/pull/1.diff | git apply`
 5. `cd -`
 6. `vagrant up saio`
 7. `vagrant ssh saio`
 8. `sudo su - swift`
 9. `source .swiftrc`
 10. `swift stat -v`
