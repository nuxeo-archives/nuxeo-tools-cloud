#!/bin/bash -e

if [ -f /opt/jenkins/bin/slave.jar ]; then
    rm /opt/jenkins/bin/slave.jar
fi
if wget --timeout 30 -O /opt/jenkins/bin/slave.jar https://qa.nuxeo.org/jenkins/jnlpJars/slave.jar; then
    chown jenkins:jenkins /opt/jenkins/bin/slave.jar
    echo "Updated slave.jar"
else
    echo "Using packaged slave.jar"
fi

