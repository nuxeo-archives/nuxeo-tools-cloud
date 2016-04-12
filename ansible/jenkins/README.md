# Ansible playbook for Jenkins slave image generation

Generate an Ubuntu image for use by Jenkins as a slave.

## Requirements

 - ansible 2.0 or later,
 - a S3 bucket for the resources cache, and the credentials to access it in your environment.

 - existing nexus user and group with ID 1003
 - existing hudson user and group with ID 1005
 - current user must have SSH access to host target as ubuntu
 - current user must be sudoer
 - current user must be member of the hudson group
 - gargantua:/volume1/Build mounted to /opt/build

## Generate/update image

Prod:

    ansible-playbook -i inventory/production/hosts slave.yml [-v]

Testing:

    ansible-playbook -i inventory/stage/hosts slave.yml -v -c local [--ask-sudo-pass]
    ansible-playbook -i inventory/stage/hosts slave.yml [-K]
    ansible-playbook playbook.yml --list-hosts

## Complete procedure with Jenkins

Log on https://console.aws.amazon.com/ec2/home?region=eu-west-1#s=Instances

### Jenkins slave template generation

Technical details:

 - based on ami-89fa71fe (from http://alestic.com/ or http://cloud-images.ubuntu.com/locator/ec2/)
(trusty 14.04 LTS amd64 ebs-ssd 20150209.1 ami-89fa71fe aki-52a34525)

Launch an instance:

 - from community AMI: ami-89fa71fe
 - with m1.small type
 - set "Jenkins slave template <DATE>" as name
 - associate the key pair
 - set 'default' security group (it's preconfigured to fit requirements)

Copy its public hostname into `nuxeo-tools-cloud/ansible/jenkins/inventory/production/hosts` under `[aws_ondemand]`.

Issue from `nuxeo-tools-cloud/ansible/jenkins/`:

     ansible-playbook -i inventory/production/hosts --limit aws_ondemand slave.yml -v

### Jenkins slave AMI generation

Select the "Jenkins slave template <DATE>" instance on AWS interface and click "Action / Create Image (EBS AMI)".

Set "`Jenkins_AMI_<DATE>_slave`" as name.
Set "`Size (GiB)`" to `50`.

Browse https://console.aws.amazon.com/ec2/v2/home?region=eu-west-1#Images

Copy the AMI ID (for instance ami-a3b1a7d7).

Repeat the operation to generate an identical AMI with name: "`Jenkins_AMI_<DATE>_ondemand`"

### Jenkins configuration

Browse https://qa.nuxeo.org/jenkins/configure#section147

In the "Cloud / Amazon EC2 / AMIs" section, set the AMI ID and check its availability ("Check AMI" button).

Instance Type: C3Xlarge.

Label "SLAVE".

Jobs must set "SLAVE" as slave restriction to use that EC2 image.

Same for the "ondemand" label with the second AMI.

You can ask for an image from https://qa.nuxeo.org/jenkins/computer/ with "Provision via EC2" button.

### AWS cleanup

Delete unused old AMIs. Delete unused associated "snapshot" volumes.

### Docker image generation

First build the nuxeo/jenkins-base image:
Add your id\_rsa.pub in docker/files/id\_rsa.pub (so ansible can connect later) then:

    cd docker
    docker build -t nuxeo/jenkins-base .

Run a container from that image, exporting the SSH port locally:

    docker run -d -t -i -p 127.0.0.1:2222:22 --name=slave nuxeo/jenkins-base

Make an inventory file for ansible to access this container:

    [multidb:children]
    docker

    [docker:children]
    slaves

    [slaves]
    container ansible_ssh_port=2222 ansible_ssh_host=127.0.0.1

Run ansible normally on this container:

    ansible-playbook -i inventory/slavetmp/hosts slave.yml -v

Commit this container:

    docker commit slave nuxeo/jenkins-docker

Tag the image for the remote registry:

    docker tag nuxeo/jenkins-docker dockerpriv.nuxeo.com:443/nuxeo/jenkins-docker

Push the image:

    docker push dockerpriv.nuxeo.com:443/nuxeo/jenkins-docker

You can then pull the image on the slaves hosts and restart the slaves containers with the new image.

