#!/bin/bash -e

echo "54.217.213.210 maven.in.nuxeo.com" >> /etc/hosts

SLAVE_NAME=$(hostname)
HOST_IP=$(ip route show | grep '^default' | awk '{print $3}')

# Add defined DB variables to environment
for v in HOST PORT NAME USER PASS ADMINNAME ADMINUSER ADMINPASS; do
    var="NX_DB_$v"
    if [ "${!var}x" != "x" ]; then
        echo ${!var} >> /etc/container_environment/NX_DB_$v
        echo "NX_DB_$v=${!var}" >> /etc/environment
    fi
    for d in MSSQL MYSQL ORACLE11G ORACLE12C PGSQL; do
        var="NX_$d_DB_$v"
        if [ "${!var}x" != "x" ]; then
            echo ${!var} >> /etc/container_environment/NX_$d_DB_$v
            echo "NX_$d_DB_$v=${!var}" >> /etc/environment
        fi
    done
done

# Add defaults to environment when variable is not defined

if [ ! -f /etc/container_environment/NX_DB_PASS ]; then
    echo pwd${SLAVE_NAME} >> /etc/container_environment/NX_DB_PASS
    echo "NX_DB_PASS=pwd${SLAVE_NAME}" >> /etc/environment
fi
if [ ! -f /etc/container_environment/NX_DB_USER ]; then
    echo user${SLAVE_NAME} >> /etc/container_environment/NX_DB_USER
    echo "NX_DB_USER=user${SLAVE_NAME}" >> /etc/environment
fi
if [ ! -f /etc/container_environment/NX_DB_HOST ]; then
    echo ${HOST_IP} >> /etc/container_environment/NX_DB_HOST
    echo "NX_DB_HOST=${HOST_IP}" >> /etc/environment
fi


if [ ! -f /etc/container_environment/NX_MSSQL_DB_ADMINNAME ]; then
    echo master >> /etc/container_environment/NX_MSSQL_DB_ADMINNAME
    echo "NX_MSSQL_DB_ADMINNAME=master" >> /etc/environment
fi
if [ ! -f /etc/container_environment/NX_MSSQL_DB_ADMINPASS ]; then
    echo nuxeo >> /etc/container_environment/NX_MSSQL_DB_ADMINPASS
    echo "NX_MSSQL_DB_ADMINPASS=nuxeo" >> /etc/environment
fi
if [ ! -f /etc/container_environment/NX_MSSQL_DB_ADMINUSER ]; then
    echo sa >> /etc/container_environment/NX_MSSQL_DB_ADMINUSER
    echo "NX_MSSQL_DB_ADMINUSER=sa" >> /etc/environment
fi
if [ ! -f /etc/container_environment/NX_MSSQL_DB_NAME ]; then
    echo db${SLAVE_NAME} >> /etc/container_environment/NX_MSSQL_DB_NAME
    echo "NX_MSSQL_DB_NAME=db${SLAVE_NAME}" >> /etc/environment
fi
if [ ! -f /etc/container_environment/NX_MSSQL_DB_PORT ]; then
    echo 1433 >> /etc/container_environment/NX_MSSQL_DB_PORT
    echo "NX_MSSQL_DB_PORT=1433" >> /etc/environment
fi

if [ ! -f /etc/container_environment/NX_MYSQL_DB_ADMINNAME ]; then
    echo mysql >> /etc/container_environment/NX_MYSQL_DB_ADMINNAME
    echo "NX_MYSQL_DB_ADMINNAME=mysql" >> /etc/environment
fi
if [ ! -f /etc/container_environment/NX_MYSQL_DB_ADMINPASS ]; then
    echo nuxeospirit >> /etc/container_environment/NX_MYSQL_DB_ADMINPASS
    echo "NX_MYSQL_DB_ADMINPASS=nuxeospirit" >> /etc/environment
fi
if [ ! -f /etc/container_environment/NX_MYSQL_DB_ADMINUSER ]; then
    echo root >> /etc/container_environment/NX_MYSQL_DB_ADMINUSER
    echo "NX_MYSQL_DB_ADMINUSER=root" >> /etc/environment
fi
if [ ! -f /etc/container_environment/NX_MYSQL_DB_NAME ]; then
    echo db${SLAVE_NAME} >> /etc/container_environment/NX_MYSQL_DB_NAME
    echo "NX_MYSQL_DB_NAME=db${SLAVE_NAME}" >> /etc/environment
fi
if [ ! -f /etc/container_environment/NX_MYSQL_DB_PORT ]; then
    echo 3306 >> /etc/container_environment/NX_MYSQL_DB_PORT
    echo "NX_MYSQL_DB_PORT=3306" >> /etc/environment
fi


if [ ! -f /etc/container_environment/NX_ORACLE11G_DB_ADMINNAME ]; then
    echo nuxeo >> /etc/container_environment/NX_ORACLE11G_DB_ADMINNAME
    echo "NX_ORACLE11G_DB_ADMINNAME=nuxeo" >> /etc/environment
fi
if [ ! -f /etc/container_environment/NX_ORACLE11G_DB_ADMINPASS ]; then
    echo nuxeo >> /etc/container_environment/NX_ORACLE11G_DB_ADMINPASS
    echo "NX_ORACLE11G_DB_ADMINPASS=nuxeo" >> /etc/environment
fi
if [ ! -f /etc/container_environment/NX_ORACLE11G_DB_ADMINUSER ]; then
    echo sys >> /etc/container_environment/NX_ORACLE11G_DB_ADMINUSER
    echo "NX_ORACLE11G_DB_ADMINUSER=sys" >> /etc/environment
fi
if [ ! -f /etc/container_environment/NX_ORACLE11G_DB_NAME ]; then
    echo nuxeo >> /etc/container_environment/NX_ORACLE11G_DB_NAME
    echo "NX_ORACLE11G_DB_NAME=nxueo" >> /etc/environment
fi
if [ ! -f /etc/container_environment/NX_ORACLE11G_DB_PORT ]; then
    echo 1520 >> /etc/container_environment/NX_ORACLE11G_DB_PORT
    echo "NX_ORACLE11G_DB_PORT=1520" >> /etc/environment
fi


if [ ! -f /etc/container_environment/NX_ORACLE12C_DB_ADMINNAME ]; then
    echo nuxeo >> /etc/container_environment/NX_ORACLE12C_DB_ADMINNAME
    echo "NX_ORACLE12C_DB_ADMINNAME=nuxeo" >> /etc/environment
fi
if [ ! -f /etc/container_environment/NX_ORACLE12C_DB_ADMINPASS ]; then
    echo nuxeo >> /etc/container_environment/NX_ORACLE12C_DB_ADMINPASS
    echo "NX_ORACLE12C_DB_ADMINPASS=nuxeo" >> /etc/environment
fi
if [ ! -f /etc/container_environment/NX_ORACLE12C_DB_ADMINUSER ]; then
    echo sys >> /etc/container_environment/NX_ORACLE12C_DB_ADMINUSER
    echo "NX_ORACLE12C_DB_ADMINUSER=sys" >> /etc/environment
fi
if [ ! -f /etc/container_environment/NX_ORACLE12C_DB_NAME ]; then
    echo nuxeo >> /etc/container_environment/NX_ORACLE12C_DB_NAME
    echo "NX_ORACLE12C_DB_NAME=nuxeo" >> /etc/environment
fi
if [ ! -f /etc/container_environment/NX_ORACLE12C_DB_PORT ]; then
    echo 1521 >> /etc/container_environment/NX_ORACLE12C_DB_PORT
    echo "NX_ORACLE12C_DB_PORT=1521" >> /etc/environment
fi


if [ ! -f /etc/container_environment/NX_PGSQL_DB_ADMINNAME ]; then
    echo template1 >> /etc/container_environment/NX_PGSQL_DB_ADMINNAME
    echo "NX_PGSQL_DB_ADMINNAME=template1" >> /etc/environment
fi
if [ ! -f /etc/container_environment/NX_PGSQL_DB_ADMINPASS ]; then
    echo nuxeospirit >> /etc/container_environment/NX_PGSQL_DB_ADMINPASS
    echo "NX_PGSQL_DB_ADMINPASS=nuxeospirit" >> /etc/environment
fi
if [ ! -f /etc/container_environment/NX_PGSQL_DB_ADMINUSER ]; then
    echo nxadmin >> /etc/container_environment/NX_PGSQL_DB_ADMINUSER
    echo "NX_PGSQL_DB_ADMINUSER=nxadmin" >> /etc/environment
fi
if [ ! -f /etc/container_environment/NX_PGSQL_DB_NAME ]; then
    echo db${SLAVE_NAME} >> /etc/container_environment/NX_PGSQL_DB_NAME
    echo "NX_PGSQL_DB_NAME=db${SLAVE_NAME}" >> /etc/environment
fi
if [ ! -f /etc/container_environment/NX_PGSQL_DB_PORT ]; then
    echo 5432 >> /etc/container_environment/NX_PGSQL_DB_PORT
    echo "NX_PGSQL_DB_PORT=5432" >> /etc/environment
fi


if [ ! -f /etc/container_environment/NX_MONGODB_SERVER ]; then
    echo ${HOST_IP} >> /etc/container_environment/NX_MONGODB_SERVER
    echo "NX_MONGODB_SERVER=${HOST_IP}" >> /etc/environment
fi
if [ ! -f /etc/container_environment/NX_MONGODB_DBNAME ]; then
    echo db${SLAVE_NAME} >> /etc/container_environment/NX_MONGODB_DBNAME
    echo "NX_MONGODB_DBNAME=db${SLAVE_NAME}" >> /etc/environment
fi

