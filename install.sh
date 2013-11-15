#!/bin/bash

if [ -z "$VIRTUAL_ENV" ]; then
cat <<EOF
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

    WARNING! You should install this in a virtualenv!

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
EOF
exit 1
fi

cd "$( dirname "$BASH_SOURCE" )"


## Install ckan + plugins + dependencies, only reading from
## the local packages archive.
pip install --find-links ./dependencies/ --no-index

cd ./sources/ckan && { { python setup.py install; }; cd -; }
cd ./sources/ckanext-datitrentinoit && { { python setup.py install; }; cd -; }


## Create configuration files in the virtualenv
./conf/ckan/setup.sh
