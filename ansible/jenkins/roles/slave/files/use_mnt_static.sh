#!/bin/bash
#
# Initializing script for making use of /mnt
#
# (C) Copyright 2013 Nuxeo SA (http://nuxeo.com/) and contributors.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the GNU Lesser General Public License
# (LGPL) version 2.1 which accompanies this distribution, and is available at
# http://www.gnu.org/licenses/lgpl-2.1.html
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# Contributors:
#   Julien Carsique
#

if [ ! -d ~jenkins/.m2/repository ]; then
    cp -a ~jenkins/.m2/repo_seed ~jenkins/.m2/repository
fi
chown -R jenkins:jenkins ~jenkins/.m2/repository

if [ ! -d /mnt/workspace ]; then
    mkdir /mnt/workspace
    chown jenkins:jenkins /mnt/workspace
fi
if [ ! -L ~jenkins/workspace ]; then
    ln -s /mnt/workspace ~jenkins/workspace
fi

