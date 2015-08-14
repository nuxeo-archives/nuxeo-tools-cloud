#!/bin/bash

cd $(dirname $0)
. aws.ini

# Prepare instance
instance=$(aws ec2 run-instances --image-id ${AMI} --count 1 --instance-type ${TYPE} --key-name ${KEYNAME} --security-groups default --region ${REGION} --user-data file://$(dirname $(pwd))/common/bootstrap.sh --query "Instances[0].InstanceId")
instance_id=$(echo -n $instance | tr -d '"')

# Wait for shutdown
while [ "$(aws ec2 describe-instances --instance-ids ${instance_id} --region ${REGION} --query "Reservations[0].Instances[0].State.Name")" != "\"stopped\"" ]; do sleep 10; done

# Create image
tstamp=$(date +"%Y%m%d%H%M")
aws ec2 create-image --instance-id ${instance_id} --name "nuxeo-6.0-lts-$tstamp" --description "Nuxeo 6.0 LTS" --region ${REGION}

# Terminate base instance
aws ec2 terminate-instances --instance-ids ${instance_id} --region ${REGION}

