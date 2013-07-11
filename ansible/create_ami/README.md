## Example playbook to create a custom AMI

Run with: ansible-playbook -i localhost create_ami.yml -v  

Region and keypair are defined in vars/ec2_settings.  
The keypair used should match your local ssh key, or you need to use ansible's --private-key option.  

The AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are assumed to be in the environment, otherwise they need to be added to the playbook.

