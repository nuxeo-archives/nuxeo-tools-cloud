#!/bin/bash

if [ -z "$1" ]; then
    template="default"
else
    template="$1"
fi

IMGNAME="$template.qcow2"

# Check root privileges
if [ "$USER" != "root" ]; then
    echo "ERROR: this script must be run as root or with sudo"
    exit 1
fi

# Install python-vm-builder if it's missing
vmbuilder=$(which vmbuilder)
if [ -z "$vmbuilder" ]; then
    echo "*** Installing missing python-vm-builder"
    DEBIAN_FRONTEND=noninteractive apt-get -q -y install python-vm-builder
fi

# Change to vmbuilder directory
cd "$(dirname $0)/$template"

# Cleanup old build
echo "*** Pre-build cleanup"
rm -rf ubuntu-kvm
rm -f "../$IMGNAME"

# Build the image
echo "*** Starting image build"
vmbuilder kvm ubuntu --config vmbuilder.cfg
if [ "$?" != "0" ]; then
    if [ -n "$SUDO_UID" ]; then
        chown -R $SUDO_UID ubuntu-kvm
    fi
    echo "*** Failure"
    exit 1
fi

echo "*** Post-build cleanup"
# Rename output image
mv ubuntu-kvm/tmp*.qcow2 "../$IMGNAME"
# Ensure owner is the caller in case of sudo
if [ -n "$SUDO_UID" ]; then
    chown $SUDO_UID "../$IMGNAME"
fi
rm -rf ubuntu-kvm

echo "*** Success"
echo "Image is available as $IMGNAME"

