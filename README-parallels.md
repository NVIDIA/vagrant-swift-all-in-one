vagrant-swift-all-in-one setup on Macbook M Series aarch64 processors with Parallels
========================

Host setup or installations

 1. Install HomeBrew
    `xcode-select --install`
    `/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`
 2. Install Vagrant
    `brew install --cask vagrant`
 3. Install Parallels
    Download and install from https://www.parallels.com/products/desktop/trial/
 4. Copy "localrc-template" file to your "localrc" file
    `cp localrc-template localrc`
 5. Make changes to the below environment variables by modifying the localrc file
    export VAGRANT_BOX=jammy-m1
    export VAGRANT_DEFAULT_PROVIDER="parallels"
 6. Make those environment variables to take effect
    `source localrc`
 7. Add "192.168.8.80    saio" into /etc/hosts
   `sudo bash -c 'echo "192.168.8.80    saio" >> /etc/hosts'`
 8. Install the vagrant plugin for parallels with `vagrant plugin install vagrant-parallels`
 9.`vagrant up`

The above setup was verified on macOS Sonoma on Apple M3 Pro.

## Supported Boxes

We do not currently [test](tests/test-paralles.sh) the Parallels provider, it
used to work with some jammy box from somewhere.
