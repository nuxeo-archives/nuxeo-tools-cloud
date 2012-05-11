This is a simple wrapper around python-vm-builder to create VM images.

It is intended to run on Ubuntu 12.04.

The default template will build a basic Ubuntu 12.04 server image for use in OpenStack with KVM (or directly in KVM using virtio).

Note: vmbuilder will sometimes create an image that is not bootable, don't forget to test it!

