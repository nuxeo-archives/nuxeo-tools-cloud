#!/usr/bin/env python

import os, sys, types

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
                help = "File, directory, URL or target platform to " + \
                  "use as a source for the distribution")
parser.add_argument("--basedir", action = "store", metavar="DEPLOY_HOME",
                help = "Directory the instance(s) will be deployed under")
parser.add_argument("--keep-dbtype", action = "store_true",
                help = "Use the DB from the config instead of the default one")
parser.add_argument("--keep-ip", action = "store_true",
                help = "Use the IP from the config instead of 0.0.0.0")
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

    # Distribution
    if args.distrib == None:
        attributes["instances"][instance_id]["distrib"] = instance["distribution"]["name"] + "-" + instance["distribution"]["version"]
    else:
        # Override distribution
        attributes["instances"][instance_id]["distrib"] = args.distrib

    # Define the user we deploy under
    attributes["instances"][instance_id]["user"] = username
    attributes["instances"][instance_id]["group"] = groupname

    # Define the deploy location
    if len(instances_root) == 1:
        instance_base = os.path.join(instances_base, instance_id)
    else:
        instance_base = os.path.join(instances_base, instance_id, instance_key)
    attributes["instances"][instance_id]["basedir"] = instance_base
    if not os.path.isdir(instance_base):
        os.makedirs(instance_base, 0700)
    os.chown(instance_base, uid, gid)

    # Add nuxeo.conf info
    conf = {}
    for keyval in instance["configuration"]["keyvals"]["keyval"]:
        conf[keyval["key"]] = keyval["value"]

    if args.keep_dbtype == True:
        attributes["instances"][instance_id]["dbtemplate"] = instance["configuration"]["dbtemplate"]
    else:
        # Override DB parameters
        attributes["instances"][instance_id]["dbtemplate"] = "default"
        if conf.has_key("nuxeo.db.name"): del conf["nuxeo.db.name"]
        if conf.has_key("nuxeo.db.host"): del conf["nuxeo.db.host"]
        if conf.has_key("nuxeo.db.port"): del conf["nuxeo.db.port"]
        if conf.has_key("nuxeo.db.user"): del conf["nuxeo.db.user"]
        if conf.has_key("nuxeo.db.password"): del conf["nuxeo.db.password"]
        if conf.has_key("nuxeo.db.jdbc.url"): del conf["nuxeo.db.jdbc.url"]
        if conf.has_key("nuxeo.db.driver"): del conf["nuxeo.db.driver"]

    if args.keep_ip == False:
        # Override IP and URL
        conf["nuxeo.bind.address"] = "0.0.0.0"
        if conf.has_key("nuxeo.url"): del conf["nuxeo.url"]

    # Override paths
    conf["nuxeo.data.dir"] = os.path.join(instance_base, "data")
    conf["nuxeo.log.dir"] = os.path.join(instance_base, "logs")
    conf["nuxeo.tmp.dir"] = os.path.join(instance_base, "tmp")
    conf["nuxeo.pid.dir"] = instance_base
        
    attributes["instances"][instance_id]["nuxeoconf"] = conf

    # Add templates info
    basetemplates = []
    if instance["configuration"]["basetemplates"].has_key("template"):
        bt = instance["configuration"]["basetemplates"]["template"]
        if type(bt) == types.ListType:
            for basetemplate in bt:
                if basetemplate == "custom":
                    print "Ignoring custom template: custom"
                else:
                    basetemplates.append(basetemplate)
        else:
            basetemplates.append(bt)
    attributes["instances"][instance_id]["basetemplates"] = basetemplates

    if instance["configuration"]["usertemplates"].has_key("template"):
        ut = instance["configuration"]["usertemplates"]["template"]
        if type(ut) == types.ListType:
            for usertemplate in ut:
                print "Ignoring custom template: " + usertemplate
        else:
            print "Ignoring custom template: " + ut

    packages = {}
    distversion = instance["distribution"]["version"]
    while distversion.find(".0-") != -1:
        distversion = distversion.replace(".0-", "-")
    for package in instance["packages"]["package"]:
        pkg_id = package["id"]
        # Remove version from ID if it's the same as the distrib
        # This is useful when overriding the distribution
        # Note: have to remove trailing ".0" from main version part
        pkgversion = package["version"]
        while pkgversion.find(".0-") != -1:
            pkgversion = pkgversion.replace(".0-", "-")
        if pkgversion == distversion:
            pkg_id = ""
            print "Overriding version for package: " + package["name"]
        packages[package["name"]] = [pkg_id, int(package["state"])]
    attributes["instances"][instance_id]["packages"] = packages

    if instance.has_key("clid"):
        attributes["instances"][instance_id]["clid"] =  instance["clid"]


node["attributes"] = attributes

run_list = []
run_list.append("recipe[nuxeo::nuxeo]")
node["run_list"] = run_list

nodefile = open(nodefilename, "w")
json.dump(node, nodefile, indent = 4)
nodefile.close()

# run chef-solo
print "Starting chef process"
#cmd = ['chef-solo', '-c', conffilename, '-j', nodefilename]
cmd = ['chef-solo', '-l', 'debug', '-c', conffilename, '-j', nodefilename]
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

