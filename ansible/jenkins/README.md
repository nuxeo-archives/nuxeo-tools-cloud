# Ansible playbook for Jenkins slave image generation

Generate an Ubuntu image for use by Jenkins as a slave.

Technical details:

 - based on ami-89fa71fe (from http://alestic.com/ or http://cloud-images.ubuntu.com/locator/ec2/)  
(trusty 14.04 LTS amd64 ebs-ssd 20150209.1 ami-89fa71fe aki-52a34525)
 - m1.small

## Requirements

 - ansible 1.8.2 or later + https://github.com/stansonhealth/ansible-modules-core/commit/250acf0e76d9858595d3f35ea3bfa8e06f6c958e

=> apply the following patch on ansible/modules/core/packaging/os/apt.py:

    247,251c247,253
    <     for pkgspec_pattern in pkgspec:
    <         pkgname_pattern, version = package_split(pkgspec_pattern)
    <
    <         # note that none of these chars is allowed in a (debian) pkgname
    <         if frozenset('*?[]!').intersection(pkgname_pattern):
    ---
    >     for pkgname_or_fnmatch_pattern in pkgspec:
    >         # note that any of these chars is not allowed in a (debian) pkgname
    >         if [c for c in pkgname_or_fnmatch_pattern if c in "*?[]!"]:
    >             if "=" in pkgname_or_fnmatch_pattern:
    >                 pkgname_or_fnmatch_pattern, version_pattern = pkgname_or_fnmatch_pattern.split('=')
    >             else:
    >                 version_pattern = None
    254,258c256,259
    <             if not ":" in pkgname_pattern:
    <                 try:
    <                     pkg_name_cache = _non_multiarch
    <                 except NameError:
    <                     pkg_name_cache = _non_multiarch = [pkg.name for pkg in cache if not ':' in pkg.name]
    ---
    >             if not ":" in pkgname_or_fnmatch_pattern:
    >                 matches = fnmatch.filter(
    >                     [pkg.name for pkg in cache
    >                      if not ":" in pkg.name], pkgname_or_fnmatch_pattern)
    260,264c261,265
    <                 try:
    <                     pkg_name_cache = _all_pkg_names
    <                 except NameError:
    <                     pkg_name_cache = _all_pkg_names = [pkg.name for pkg in cache]
    <             matches = fnmatch.filter(pkg_name_cache, pkgname_pattern)
    ---
    >                 matches = fnmatch.filter(
    >                     [pkg.name for pkg in cache], pkgname_or_fnmatch_pattern)
    >
    >             if version_pattern is not None:
    >                 matches = [ match+'='+version_pattern for match in matches ]
    267c268
    <                 m.fail_json(msg="No package(s) matching '%s' available" % str(pkgname_pattern))
    ---
    >                 m.fail_json(msg="No package(s) matching '%s' available" % str(pkgname_or_fnmatch_pattern))
    271,272c272
    <             # No wildcards in name
    <             new_pkgspec.append(pkgspec_pattern)
    ---
    >             new_pkgspec.append(pkgname_or_fnmatch_pattern)

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
Set "`Jenkins_AMI_YYYYMMDD_slave`" as name.
Browse https://console.aws.amazon.com/ec2/v2/home?region=eu-west-1#Images:
Copy the AMI ID (for instance ami-a3b1a7d7).

Repeat the operation to generate an identical AMI with name: "`Jenkins_AMI_YYYYMMDD_ondemand`"

### Jenkins configuration

Browse https://qa.nuxeo.org/jenkins/configure#section147
In the "Cloud / Amazon EC2 / AMIs" section, set the AMI ID and check its availability ("Check AMI" button).
Instance Type: C3Xlarge.
Label "SLAVE".
Jobs must set "SLAVE" as slave restriction to use that EC2 image.

Same for the "ondemand" label with the second AMI.

You can ask for an image from https://qa.nuxeo.org/jenkins/computer/ with "Provision via EC2" button.

