#!/bin/bash

chefdir=$(cd "$(dirname "$0")"/..; pwd -P)
tmpdir=$(mktemp -d)

echo "Temp dir is $tmpdir"

function create_file() {
    sed -e "s,\${tmpdir},${tmpdir},g" -e "s,\${chefdir},${chefdir},g" "${chefdir}/templates/$1" > "${tmpdir}/$1"
}

create_file conf.rb
create_file node.json

sudo chef-solo -c "${tmpdir}/conf.rb" -j "${tmpdir}/node.json"

# Cleanup
sudo rm -rf "${tmpdir}"

