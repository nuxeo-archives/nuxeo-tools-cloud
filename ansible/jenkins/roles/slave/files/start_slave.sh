#!/bin/bash

sudo bash -c 'echo "176.57.246.12 maven.in.nuxeo.com" >> /etc/hosts'

SLAVE_NAME=$(hostname)
HOST_IP=$(ip route show | grep '^default' | awk '{print $3}')

export NX_DB_PASS=pwd${SLAVE_NAME}
export NX_DB_USER=user${SLAVE_NAME}
export NX_DB_HOST=${HOST_IP}

export NX_MSSQL_DB_ADMINNAME=master
export NX_MSSQL_DB_ADMINPASS=nuxeo
export NX_MSSQL_DB_ADMINUSER=sa
export NX_MSSQL_DB_NAME=db${SLAVE_NAME}
export NX_MSSQL_DB_PORT=1433

export NX_MYSQL_DB_ADMINNAME=mysql
export NX_MYSQL_DB_ADMINPASS=nuxeospirit
export NX_MYSQL_DB_ADMINUSER=root
export NX_MYSQL_DB_NAME=db${SLAVE_NAME}
export NX_MYSQL_DB_PORT=3306

export NX_ORACLE11G_DB_ADMINNAME=nuxeo
export NX_ORACLE11G_DB_ADMINPASS=nuxeo
export NX_ORACLE11G_DB_ADMINUSER=sys
export NX_ORACLE11G_DB_NAME=nuxeo
export NX_ORACLE11G_DB_PORT=1520

export NX_ORACLE12C_DB_ADMINNAME=nuxeo
export NX_ORACLE12C_DB_ADMINPASS=nuxeo
export NX_ORACLE12C_DB_ADMINUSER=sys
export NX_ORACLE12C_DB_NAME=nuxeo
export NX_ORACLE12C_DB_PORT=1521

export NX_PGSQL_DB_ADMINNAME=template1
export NX_PGSQL_DB_ADMINPASS=nuxeospirit
export NX_PGSQL_DB_ADMINUSER=nxadmin
export NX_PGSQL_DB_NAME=db${SLAVE_NAME}
export NX_PGSQL_DB_PORT=5432

/etc/init.d/xvfb start

java -jar ~/bin/slave.jar

