# VSAIO using libvirt

VSAIO now supports running in libvirt/kvm. Be sure to pick a libvirt box in
localrc and away you go. But you might need to make sure you have libvirt
running for your user (unless you want to sudo everything).

Install libvirtd etc. On fedora this is easy:
	sudo dnf install @virtualization

Let's make sure its running:
	sudo systemctl start libvirtd
	sudo systemctl enable libvirtd

Make sure you're user is apart of the libvirt group:
	sudo gpasswd -a matt libvirt

We need to enable read write to domain socket for the libvirt group, uncomment
and make sure these are set in /etc/libvirt/libvirtd.conf:
	unix_sock_group = "libvirt"
	auth_unix_rw = "none"
	auth_unix_ro = "none"

Then restart libvirtd
	sudo systemctl restart libvirtd

Add this to your localrc

	export LIBVIRT_DEFAULT_URI="qemu:///system"


## Supported Boxes

We currently [test](tests/test-libvirt.sh) the libvirt provider with the
following `VAGRANT_BOX` options:

 * bento/ubuntu-24.04
 * bento/ubuntu-22.04

FWIW libvirt bringup works perfectly reliably for me, but the unittests seem to
fail with hard to reproduce "timing issues" more frequently than they do for
the vmware or vbox providers OMM.  AFAIK no one has seen the test-libvirt.sh
script complete without error.
