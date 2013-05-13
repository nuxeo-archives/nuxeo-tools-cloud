# Ansible playbook for Jenkins slave image generation

Generate an Ubuntu image for use by Jenkins as a slave.

Technical details:

 - based on ami-ce7b6fba (from http://alestic.com/).
 - m1.large

## Generate/update image

ansible-playbook -i production slave.yml

## Testing

ansible-playbook -i stage slave.yml -v -c local [--ask-sudo-pass]

ansible-playbook -i stage slave.yml [-K]

ansible-playbook playbook.yml --list-hosts

