#!/usr/bin/env python

import os, sys

# pre-validation
if os.getuid() != 0:
    print "ERROR: This script should be run as root or sudo."
    sys.exit(1)

if sys.version_info.major != 2 or sys.version_info.minor <7:
    print "ERROR: This script is only compatible with Python 2.7 <= version < 3"
    sys.exit(1)

if sys.platform == "win32":
    print "ERROR: This script doesn't work in Windows"
    sys.exit(1)

import argparse, tempfile, subprocess, shutil, pwd, grp

try:
    import simplejson as json
except ImportError:
    import json
from libs import xmltodict

# for debugging
import pprint
pp = pprint.PrettyPrinter(indent = 2)

# options parsing
parser = argparse.ArgumentParser()
filegroup = parser.add_mutually_exclusive_group(required = True)
filegroup.add_argument("-j", "--json", metavar="JSON_FILE", action = "store",
           help = "JSON file to read the instance description from")
filegroup.add_argument("-x", "--xml", metavar="XML_FILE", action = "store",
           help = "XML file to read the instance description from")
parser.add_argument("--distrib", action = "store", metavar="DISTRIBTION_DIR",
           help = "File, directory or target platform to " + \
                  "use as a source for the distribution")
parser.add_argument("--basedir", action = "store", metavar="DEPLOY_HOME",
           help = "Directory the instance(s) will be deployed under")
parser.add_argument("id", action = "store",
           help = "Local ID to attribute to the instance")
args = parser.parse_args()


# common paths
scriptdir = os.path.realpath(os.path.dirname(__file__))

chefdir = os.path.realpath(os.path.join(scriptdir, os.path.pardir))
cookbookdir = os.path.join(chefdir, "cookbooks")

tmpdir = tempfile.mkdtemp(prefix="chef-")
cachedir = os.path.join(tmpdir, "cache")

# chef-solo configuration
conffilename = os.path.join(tmpdir, "conf.rb")
conffile = open(conffilename, "w")
conffile.write('file_cache_path "%s"\n' % (cachedir,))
conffile.write('cookbook_path "%s"\n' % (cookbookdir,))
conffile.close()

# parse instance(s) description
if args.json != None:
    try:
        jsonfilename = args.json
        if jsonfilename == "-":
            jsonfile = sys.stdin
        else:
            jsonfile = open(jsonfilename, "r")
        jsondata = unicode(file.read(jsonfile))
        instances = json.loads(jsondata)
        jsonfile.close()
    except:
        print "Could not parse JSON."
        sys.exit(1)
else:
    try:
        xmlfilename = args.xml
        if xmlfilename == "-":
            xmlfile = sys.stdin
        else:
            xmlfile = open(xmlfilename, "r")
        instances = xmltodict.parse(xmlfile, attr_prefix = '')
        xmlfile.close()
    except:
        print "Could not parse XML."
        sys.exit(1)

"""
Config files describing a single instance should be in the format output
by 'nuxeoctl showconf --json/--xml' (the root 'instance' element can be renamed)

Config files describing multiples instances should have an 'instances' root
element. Sub-elements should have different names.

JSON example:
{"instances": { "test1": { some stuff },
                "test2": { other stuff }
}

XML example:
<instances>
    <test1>
        some stuff
    </test1>
    <test2>
        other stuff
    </test2>
</instances>

"""
if len(instances) !=1:
    print "Wrong format for JSON/XML file."
    sys.exit(1)

# Prepare for instances loop

if instances.keys()[0] == u"instances":
    instances_root = instances[u"instances"]
else:
    instances_root = instances

# Try to find out who we are and where we live
username = os.getenv("SUDO_USER")
if username == None or username == "":
    username = os.getenv("USER")
userhome = pwd.getpwnam(username).pw_dir
uid = pwd.getpwnam(username).pw_uid
gid = pwd.getpwnam(username).pw_gid
groupname = grp.getgrgid(gid).gr_name

if args.basedir != None:
    instances_base = args.basedir
else:
    instances_base = os.path.join(userhome, "nxinstances")
if not os.path.isdir(instances_base):
    os.makedirs(instances_base, 0700)
os.chown(instances_base, uid, gid)


# chef-solo attributes
nodefilename = os.path.join(tmpdir, "node.xml")

node = {}

attributes = {}
attributes["instances"]={}

# define instances
for instance_key in instances_root.keys():

    instance = instances_root[instance_key]

    instance_id = args.id
    if len(instances_root) != 1:
        instance_id = instance_id + "-" + instance_key
    attributes["instances"][instance_id] = {}

    # Override distribution with local one / targetplatform
    if args.distrib != None:
        if os.path.isfile(args.distrib):
            attributes["instances"][instance_id]["localplatform"] = args.distrib
        else:
            attributes["instances"][instance_id]["targetplatform"] = args.distrib

    # Define the user we deploy under
    attributes["instances"][instance_id]["user"] = username
    attributes["instances"][instance_id]["group"] = groupname

    # Define where we deploy the instance
    if len(instances_root) == 1:
        instance_base = os.path.join(instances_base, instance_id)
    else:
        instance_base = os.path.join(instances_base, instance_id, instance_key)
    attributes["instances"][instance_id]["basedir"] = instance_base
    if not os.path.isdir(instances_base):
        os.makedirs(instance_base, 0700)
    os.chown(instances_base, uid, gid)

    # TODO: Add real instance info


node["attributes"] = attributes

run_list = []
run_list.append("recipe[nuxeo::nuxeo]")
node["run_list"] = run_list

nodefile = open(nodefilename, "w")
json.dump(node, nodefile, indent = 4)
nodefile.close()

# run chef-solo
print "Starting chef process"
cmd = ['chef-solo', '-c', conffilename, '-j', nodefilename]
#cmd = ['chef-solo', '-l', 'debug', '-c', conffilename, '-j', nodefilename]
try:
    subprocess.check_call(cmd, shell = False)
except:
    # Give tmpdir ownership back to sudoer
    for root, dirs, files in os.walk(tmpdir):
        os.chown(os.path.join(tmpdir, root), uid, gid)
        for f in files:
            os.chown(os.path.join(tmpdir, root, f), uid, gid)
    raise
    
# cleanup tmpdir if all went well
try:
    shutil.rmtree(tmpdir)
except:
    print "Directory %s could not be deleted" % (tmpdir,)

