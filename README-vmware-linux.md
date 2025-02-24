# VMware on Linux

VMware Workstation is now available for free and supports Linux.

## Installation

Registering an account with [Broadcom](https://profile.broadcom.com/web/registration)
is a pre-requisite.

IME, it can be challenging to find the link to
[Download VMware Workstation](https://knowledge.broadcom.com/external/article/344595/downloading-and-installing-vmware-workst.html)

The vagrant docs suggest the required
[vagrant-vmware-utility](https://developer.hashicorp.com/vagrant/docs/providers/vmware/vagrant-vmware-utility)
is available via their
[official package repos](https://developer.hashicorp.com/vagrant/install/vmware#linux),
but [IME](https://github.com/hashicorp/vagrant-vmware-desktop/issues/144)
on Ubuntu I had to download `.deb` and install it manually:

    sudo dpkg -i ~/Downloads/vagrant-vmware-utility_1.0.23-1_amd64.deb

You will also need to install the `vagrant-vmware-desktop` plugin for `vagrant`

    vagrant plugin install vagrant-vmware-desktop

## Configuration

### VMWare Kernel Module

Make sure your VMware kernel modules are signed and installed:

```
$ lsmod | egrep "(vmmon|vmnet)"
vmnet                  73728  13
vmmon                 163840  1
```

Most likely if you just installed VMWare and haven't yet used it successfully
those needed kernel modules will NOT be listed.  Probably because they can't load:

```
$ sudo modprobe -a vmmon
modprobe: ERROR: could not insert 'vmmon': Key was rejected by service
```

Hopefully you've been through the self-signed kernel module song and dance
before; this script worked for me:

```
#!/bin/bash

VMWARE_MOD_PREFIX=vm

# create some keys for self signed modules
mkdir /root/module-signing || true
openssl req -new -x509 -newkey rsa:2048 \
    -keyout /root/module-signing/MOK.priv -outform DER \
    -out /root/module-signing/MOK.der -nodes -days 36500 \
    -subj "/CN=SELFSIGNED/"
# prompt to install them (with passphrase) on reboot
mokutil --import /root/module-signing/MOK.der

# sign the VMWare kernel modules
KERNEL_VERSION=$(uname -r)
for modfile in $(ls /lib/modules/${KERNEL_VERSION}/misc/${VMWARE_MOD_PREFIX}*.ko); do
  echo "Signing $modfile"
  /usr/src/linux-headers-${KERNEL_VERSION}/scripts/sign-file sha256 \
                                /root/module-signing/MOK.priv \
                                /root/module-signing/MOK.der "$modfile"
done
```

### vagrant-vmware-utility license

Probably because VMware changed it's license rules in May '24 the service file
provided with vagrant-vmware-utility doesn't work by default:

```
Bringing machine 'default' up with 'vmware_desktop' provider...
==> default: Cloning VMware VM: 'bento/ubuntu-24.04'. This can take some time...
An error occurred while executing `vmrun`, a utility for controlling
VMware machines. The command and output are below:

Command: ["-T", "player", "snapshot", "/home/cgerrard/.vagrant.d/boxes/bento-VAGRANTSLASH-ubuntu-24.04/202502.21.0/amd64/vmware_desktop/ubuntu-24.04-amd64.vmx", "77a2df51-4e2f-48f2-a103-bb993b56910e", {:notify=>[:stdout, :stderr]}]

Stdout: Error: The operation is not supported

Stderr: Warning: program compiled against libxml 212 using older 209
```

... what seems to be going on is the plugin is "detecting" the "wrong" license
and the `-T` argument gets set to `player` instead of `ws`.

The recommeneded (?) [workaround](https://github.com/hashicorp/vagrant-vmware-desktop/issues/91#issuecomment-267965302)
is to change the license reported by the vmware-utility API service by adding a
`-license-override professional` CLI option to the `ExecStart` line in the
systemd unit file for `vagrant-vmware-utility.service`

```
$ cat /usr/lib/systemd/system/vagrant-vmware-utility.service
[Unit]
Description=Vagrant VMware Utility
After=network.target

[Service]
Type=simple
ExecStart=/opt/vagrant-vmware-desktop/bin/vagrant-vmware-utility api -config-file=/opt/vagrant-vmware-desktop/config/service.hcl -license-override professional
Restart=on-abort

[Install]
WantedBy=multi-user.target
```

And then reload and restart:

```
sudo systemctl daemon-reload
sudo systemctl restart vagrant-vmware-utility.service
```

### Update localrc

Tell vagrant which provider to want in your `localrc`

    export VAGRANT_DEFAULT_PROVIDER=vmware_desktop

FWIW `export VAGRANT_DEFAULT_PROVIDER=vmware_workstation` may *seem* to work,
but it won't run the custom `vmware_desktop` config in the Vagrantfile.

## Supported Boxes

We currently [test](tests/test-vmware-linux.sh) the VMWare provider on Linux
with the following `VAGRANT_BOX` options:

 * bento/ubuntu-24.04
