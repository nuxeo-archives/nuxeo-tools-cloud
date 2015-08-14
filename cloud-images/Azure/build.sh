#!/bin/bash

cd $(dirname $0)
. azure.ini

tstamp=$(date +"%Y%m%d%H%M")

# Create random password compatible with Azure policy
while true; do
    nxpass=$(pwgen -n -c -y 10 1)
    if [ "x$(echo -n $nxpass | tr -d '[:alnum:]@#%^&+=')x" == "xx" ]; then
        break
    fi
done
echo "Temporary password: $nxpass"

# Prepare instance
azure vm create --vm-name nuxeo-template-${tstamp} --vm-size ${TYPE} --ssh 22 --location "East US" nuxeo-template-${tstamp} ${IMAGE} ubuntu $nxpass --custom-data $(dirname $(pwd))/common/bootstrap.sh

# Wait for shutdown
while [ "$(azure vm show nuxeo-template-${tstamp} --json | grep 'InstanceStatus' |  tr '"' ' ' | awk '{print $3}')" != "StoppedVM" ]; do sleep 10; done

# Create image and delete instance
azure vm capture -t -e "Nuxeo 6.0 LTS" nuxeo-template-${tstamp} nuxeo-6.0-lts-${tstamp}

# Delete service
azure service delete nuxeo-template-${tstamp} -q

