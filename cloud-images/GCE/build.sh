#!/bin/bash

cd $(dirname $0)
. gce.ini

tstamp=$(date +"%Y%m%d%H%M")

# Prepare instance
gcloud compute instances create nuxeo-template-${tstamp} --image ubuntu-14-04 --machine-type ${TYPE} --zone ${ZONE} --metadata-from-file startup-script=$(dirname $(pwd))/common/bootstrap.sh --tags http-server,https-server

# Wait for shutdown
while [ "$(gcloud compute instances describe nuxeo-template-${tstamp} --zone ${ZONE} --format text | grep -i '^status:' | awk '{print $2}')" != "TERMINATED" ]; do sleep 10; done

# Delete instance but keep disk
gcloud compute instances delete nuxeo-template-${tstamp} --keep-disks boot --zone ${ZONE} -q

# Create image
gcloud compute images create nuxeo-6-lts-${tstamp} --source-disk nuxeo-template-${tstamp} --source-disk-zone ${ZONE}

# Delete disk
gcloud compute disks delete nuxeo-template-${tstamp} --zone ${ZONE} -q

