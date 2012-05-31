#!/usr/bin/env python

import os
import sys
import tempfile
try:
    import simplejson as json
except ImportError:
    import json
import subprocess
import shutil


if (os.getuid() != 0):
    print "This script should be run as root or sudo."
    sys.exit(1)

scriptdir = os.path.realpath(os.path.dirname(__file__))

chefdir = os.path.join(scriptdir, os.path.pardir)
cookbookdir = os.path.join(chefdir, "cookbooks")

tmpdir = tempfile.mkdtemp(prefix="chef-")
cachedir = os.path.join(tmpdir, "cache")

# chef-solo configuration
conffilename = os.path.join(tmpdir, "conf.rb")
conffile = open(conffilename, "w")
conffile.write('file_cache_path "%s"\n' % (cachedir,))
conffile.write('cookbook_path "%s"\n' % (cookbookdir,))
conffile.close()

# chef-solo attributes
jsonfilename = os.path.join(tmpdir, "node.json")

node = {}

attributes = {}
attributes["instances"]={}

# define instances
attributes["instances"]["nxtest"] = {}
attributes["instances"]["nxtest"]["home"] = "/home/nxtest"

node["attributes"] = attributes

run_list = []
run_list.append("recipe[nuxeo::test]")
node["run_list"] = run_list

jsonfile = open(jsonfilename, "w")
json.dump(node, jsonfile, indent = 4)
jsonfile.close()

# run chef-solo
print "Starting chef process"
cmd = ['chef-solo', '-c', conffilename, '-j', jsonfilename]
subprocess.check_call(cmd, shell = False)

# cleanup
try:
    shutil.rmtree(tmpdir)
except:
    print "Directory %s could not be deleted" % (tmpdir,)

