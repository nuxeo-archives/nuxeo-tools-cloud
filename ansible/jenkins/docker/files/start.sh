#!/bin/bash

mkdir -p /home/ubuntu/.ssh
chmod -R og-rwx /home/ubuntu/.ssh
chown -R ubuntu:ubuntu /home/ubuntu/.ssh

# Start Xvfb if installed

if [ -f /usr/bin/Xvfb ]; then

    . /lib/init/vars.sh
    . /lib/lsb/init-functions

    start-stop-daemon --start --name Xvfb --background --chuid jenkins --startas /usr/bin/Xvfb -- :1 -ac -screen 0 1280x1024x16
    #start-stop-daemon --start --name x11vnc --background --chuid jenkins --startas /usr/bin/x11vnc -- -display :1 -nopw -forever -quiet
    start-stop-daemon --start --name fluxbox --background --chuid jenkins --startas /usr/bin/fluxbox -- -display :1

fi


# Set workspace rights if mounted

if [ -d /opt/jenkins/workspace ]; then
    chown jenkins:jenkins /opt/jenkins/workspace
fi


mkdir -p /var/run/sshd
/usr/sbin/sshd -D


# Stop Xvfb if installed

if [ -f /usr/bin/Xvfb ]; then

    start-stop-daemon --chuid jenkins --stop --name fluxbox
    #start-stop-daemon --chuid jenkins --stop --name x11vnc
    start-stop-daemon --chuid jenkins --stop --name Xvfb

fi
