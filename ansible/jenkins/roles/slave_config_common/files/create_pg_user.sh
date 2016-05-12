#!/bin/bash -e

# Wait a bit for the database to be up
sleep 10

su postgres -c "psql template1 -f-" << EOF
DROP USER IF EXISTS nxadmin;
CREATE USER nxadmin WITH PASSWORD 'nuxeo' CREATEDB SUPERUSER;
EOF

