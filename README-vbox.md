# VirtualBox

VirtualBox is currently the default vagrant virtualization provider.  But if
you want to be explicit you can add the following to your `localrc`

    export VAGRANT_DEFAULT_PROVIDER=virtualbox

## Installation

You will need to [download](https://www.virtualbox.org/wiki/Downloads) and
isntall VirtualBox on your host.

## Configuration

By default VirtualBox only let's you create [Host-Only Networks](https://www.virtualbox.org/manual/ch06.html#network_hostonly)
in the range `192.168.56.0/21`

This causes a conflict because the default `IP` assigned by the
`localrc-template` is `192.168.8.80`

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

It's recommened you configure `/etc/vbox/networks.conf` to allow your required
networks, e.g. `192.168.8.0/24`

```
$ cat /etc/vbox/networks.conf 
* 192.168.8.0/24

```

You may need to create the file as root, 0644 permissions should be fine.

Alternatively, you can change the network associated with the vagrant vm by
changing the `IP` in your `localrc`.

```
$ diff localrc-template localrc.vbox-default-network 
11c11
< export IP=192.168.8.80
---
> export IP=192.168.56.80
```

## Supported Boxes

We currently [test](tests/test-vbox.sh) the VirtualBox provider with the
following `VAGRANT_BOX` options:

 * bento/ubuntu-24.04
 * bento/ubuntu-22.04
 * bento/ubuntu-20.04

## Troubleshooting
### Conflict with KVM
You may potentially run into the following error on an Intel-based Linux system
as soon as you attempt runing `vagrant up`:
```text
Bringing machine 'default' up with 'virtualbox' provider...
...
==> default: Running 'pre-boot' VM customizations...
==> default: Booting VM...
There was an error while executing `VBoxManage`, a CLI used by Vagrant
for controlling VirtualBox. The command and stderr is shown below.

Command: ["startvm", "ec1a1833-04c3-4da1-9be7-c22297df17ad", "--type", "headless"]

Stderr: VBoxManage: error: VirtualBox can't operate in VMX root mode. Please disable the KVM kernel extension, recompile your kernel and reboot (VERR_VMX_IN_VMX_ROOT_MODE)
VBoxManage: error: Details: code NS_ERROR_FAILURE (0x80004005), component ConsoleWrap, interface IConsole
```

 In this case, unloading the KVM kernel modules may fix the issue:
```sh
$ lsmod | grep kvm
kvm_intel               245760  0
kvm                  1425408  1 kvm_intel
irqbypass              12288  1 kvm

$ modprobe -r kvm_intel kvm
```
Now re-run `vagrant up` to boot the VM. Note that by default the KVM kernel
modules are reloaded after a system reboot. You can prevent that behavior
permanently by e.g. updating `/etc/modprobe.d/blacklist.conf`.

