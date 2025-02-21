vmware_desktop provider setup on Macbook M Series aarch64 processor
===================================================================

 1. Install HomeBrew
    `xcode-select --install`
    `/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`

 2. Install Vagrant
    `brew install --cask vagrant`

 3. Install Vmware Fusion

    Registering an account with Broadcom is a pre-requisite.

    Download Vmware Fusion from https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware+Fusion

    Note: 'Fusion' is the MAC version of Vmware Desktop. The following may
    also work with Vmware Desktop on Linux but has not been verified.

    Install vmware utility:
    `brew install --cask vagrant-vmware-utility`

    Install the vmware-desktop vagrant plugin:
    `sudo vagrant plugin install vagrant-vmware-desktop`

4. Create and source a localrc file, then `vagrant up`, as documented in README file.

Note: useful vmware tools such as vmrun were installed at "/Applications/VMware Fusion.app/Contents/Library".
Add this to your path to use:

  `vmrun list`

to show all running vmware vm's.


The above setup was verified on macOS Sequoia 15.2 on Apple M1 Pro, using:
Vagrant 2.4.3
Vmware Version 13.6.2 (24409261)
