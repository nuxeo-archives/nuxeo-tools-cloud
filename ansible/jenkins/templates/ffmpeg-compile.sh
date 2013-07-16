#!/bin/bash
#
# Initializing script for locally compiling ffmpeg if libx264 encoder is missing
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

# exit if x264 is already available
x264 --help >/dev/null 2>&1 && exit 0
git clone https://github.com/nuxeo/ffmpeg-nuxeo /tmp/ffmpeg-nuxeo
cd /tmp/ffmpeg-nuxeo
git checkout master
# libfaac availability is automatically detected
./build-all.sh
