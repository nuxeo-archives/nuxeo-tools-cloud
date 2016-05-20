#!/bin/bash -e

if [ -f /opt/jenkins/bin/slave.jar ]; then
    rm /opt/jenkins/bin/slave.jar
fi
wget -O /opt/jenkins/bin/slave.jar https://qa.nuxeo.org/jenkins/jnlpJars/slave.jar
chown jenkins:jenkins /opt/jenkins/bin/slave.jar

