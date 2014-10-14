# Ansible playbook for Jenkins slave image generation

Generate an Ubuntu image for use by Jenkins as a slave.

Technical details:

 - based on ami-ce7b6fba (from http://alestic.com/).
 - m1.xlarge

## Requirements

 - ansible 1.7.2 or later
 - existing nexus user and group with ID 1003
 - existing hudson user and group with ID 1005
 - current user must have SSH access to host target as ubuntu
 - current user must be sudoer
 - current user must be member of the hudson group
 - gargantua:/volume1/Build mounted to /opt/build

For docker tests:

 - current user must be in docker group (to invoke docker commands)
 - docker-py must be installed (pip install docker-py)
 

## Generate/update image

Prod:
ansible-playbook -i hosts-production slave.yml [-v]

## Testing

ansible-playbook -i hosts-stage slave.yml -v -c local [--ask-sudo-pass]
ansible-playbook -i hosts-stage slave.yml [-K]
ansible-playbook playbook.yml --list-hosts

Docker test:
ansible-playbook -i hosts-docker, docker.yml -v

## Complete procedure with Jenkins

Log on https://console.aws.amazon.com/ec2/home?region=eu-west-1#s=Instances

### Jenkins slave template generation

Launch an instance:

 - from community AMI: ami-ce7b6fba 
 - with m1.small type
 - set "Jenkins slave template" as name
 - associate the key pair
 - set default security group (it's preconfigured to fit requirements)
 
Copy its public hostname into `nuxeo-tools-cloud/ansible/jenkins/production`.  
Issue from `nuxeo-tools-cloud/ansible/jenkins/`:

     ansible-playbook -i production slave.yml -v
     
### Jenkins slave AMI generation

Select the "Jenkins slave template" instance on AWS interface and click "Action / Create Image (EBS AMI)".  
Set "`Jenkins_slave_image_...`" as name.
Browse https://console.aws.amazon.com/ec2/v2/home?region=eu-west-1#Images:  
Copy the AMI ID (for instance ami-a3b1a7d7).

### Jenkins configuration

Browse https://qa.nuxeo.org/jenkins/configure#section147  
In the "Cloud / Amazon EC2 / AMIs" section, set the AMI ID and check its availability ("Check AMI" button).
Instance Type: M1Xlarge.  
 


Jobs must set "ondemand" as slave restriction to use that EC2 image.


You can ask for an image from https://qa.nuxeo.org/jenkins/computer/ with "Provision via EC2" button.

