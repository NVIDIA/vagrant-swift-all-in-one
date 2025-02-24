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
