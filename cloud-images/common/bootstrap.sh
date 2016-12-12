#!/bin/bash

# Increase open files limit
echo '*       soft    nofile      4096' >> /etc/security/limits.conf
echo '*       hard    nofile      8192' >> /etc/security/limits.conf

# Add the nuxeo repository to the repository list
echo "deb http://apt.nuxeo.org/ xenial releases" > /etc/apt/sources.list.d/nuxeo.list
# Register the nuxeo key
wget -q -O- http://apt.nuxeo.org/nuxeo.key | apt-key add -

# Pre-accept Sun Java license & set Nuxeo options
echo nuxeo nuxeo/bind-address select 127.0.0.1 | debconf-set-selections
echo nuxeo nuxeo/http-port select 8080 | debconf-set-selections
echo nuxeo nuxeo/database select Autoconfigure PostgreSQL | debconf-set-selections

# Upgrade packages and install ssh, vim
export DEBIAN_FRONTEND=noninteractive
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8
apt-get update
apt-get -q -y upgrade
apt-get -q -y install apache2
apt-get -q -y install openssh-server openssh-client vim postfix pwgen curl sudo
apt-get -q -y install ccextractor-nuxeo

# Secure postfix
perl -p -i -e "s/^inet_interfaces\s*=.*$/inet_interfaces=127.0.0.1/" /etc/postfix/main.cf

# Install Java 8
curl -o/tmp/jdk-8-linux-x64.tgz -L --insecure --header 'Cookie: oraclelicense=accept-securebackup-cookie' 'http://download.oracle.com/otn-pub/java/jdk/8u111-b14/jdk-8u111-linux-x64.tar.gz'
tar xzf /tmp/jdk-8-linux-x64.tgz -C /usr/lib/jvm
rm /tmp/jdk-8-linux-x64.tgz
ln -s /usr/lib/jvm/jdk1.8.0_111 /usr/lib/jvm/java-8
update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-8/jre/bin/java 1081
update-alternatives --set java /usr/lib/jvm/java-8/jre/bin/java

# Install Nuxeo without sctarting it
echo exit 101 > /usr/sbin/policy-rc.d
chmod +x /usr/sbin/policy-rc.d
apt-get -q -y install nuxeo
rm /usr/sbin/policy-rc.d

# Update some defaults
update-alternatives --set editor /usr/bin/vim.basic

# Configure reverse-proxy
mkdir -p /etc/apache2/virtualhosts
cat << EOF > /etc/apache2/virtualhosts/nuxeo
CustomLog /var/log/apache2/nuxeo_access.log combined
ErrorLog /var/log/apache2/nuxeo_error.log

DocumentRoot /var/www

ProxyRequests Off
<Proxy *>
    Order allow,deny
    Allow from all
</Proxy>

RewriteEngine On
RewriteRule ^/$ /nuxeo/ [R,L]
RewriteRule ^/nuxeo$ /nuxeo/ [R,L]

ProxyPass        /nuxeo/ http://localhost:8080/nuxeo/
ProxyPassReverse /nuxeo/ http://localhost:8080/nuxeo/
ProxyPreserveHost On
EOF
cat << EOF > /etc/apache2/sites-available/nuxeo.conf
<VirtualHost _default_:80>
    Include virtualhosts/nuxeo
</VirtualHost>
EOF

a2enmod proxy proxy_http rewrite
a2dissite 000-default
a2ensite nuxeo

# Drop unused "main" PostgreSQL cluster
pg_dropcluster --stop $(pg_lsclusters -h | grep main | awk '{print $1}') main

# Prepare first boot
update-rc.d -f nuxeo remove
cat << EOF > /etc/init.d/firstboot
#!/bin/bash -e
### BEGIN INIT INFO
# Provides:          firstboot
# Required-Start:    \$local_fs \$remote_fs \$network \$syslog \$postgresql
# Required-Stop:     \$local_fs \$remote_fs \$network \$syslog \$postgresql
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Firstboot
# Description:       Executes commands on first boot
### END INIT INFO

case "\$1" in
  start)
    if [ -f /firstboot_done ]; then
        exit 0
    fi
    echo "DO NOT REMOVE THIS FILE" > /firstboot_done
    # Wait for PostgreSQL to be up
    until pg_lsclusters | grep nuxeodb | grep online; do sleep 1; done
    # Generate new DB password
    pgpass=\$(pwgen -c1)
    echo \$pgpass > /tmp/pgpass # DEBUG
    su postgres -c "psql template1 -c \"alter user nuxeo with password '\$pgpass'\""
    perl -p -i -e "s/^nuxeo.db.password\s*=.*$/nuxeo.db.password=\$pgpass/" /etc/nuxeo/nuxeo.conf

    # Enable nuxeo & deactivate firstboot
    update-rc.d nuxeo defaults
    invoke-rc.d nuxeo start
    exit 0
    ;;

  *)
    # Don't do anything except on start
    exit 0
    ;;

esac
EOF
chmod +x /etc/init.d/firstboot
update-rc.d firstboot defaults

# Prepare cleanup
cat << EOF > /mnt/cleanup.sh
#!/bin/bash
apt-get clean
rm -f /etc/udev/rules.d/70-persistent*
rm -rf /var/lib/cloud/*
rm -rf /tmp/*
rm -rf /var/tmp/*
shred -u /root/.bash_history
shred -u /home/ubuntu/.bash_history
invoke-rc.d rsyslog stop
find /var/log -type f -exec rm {} \;
if [ -f /usr/sbin/waagent ]; then
    /usr/sbin/waagent -deprovision -force
else
    rm -f /etc/ssh/*key*
    rm -rf /root/.ssh
    rm -rf /home/ubuntu/.ssh
fi
shutdown -h now
EOF
chmod +x /mnt/cleanup.sh

# Wait for cloud-init to finish, run cleanup and stop instance
at -t $(date --date="now + 2 minutes" +"%Y%m%d%H%M") -f /mnt/cleanup.sh

