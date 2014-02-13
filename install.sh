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

## Fail fast, otherwise errors might get hidden..
set -e

PIP_LOCAL="pip install --find-links file://${PWD}/dependencies/ --no-index"


## Install ckan + plugins + dependencies, only reading from
## the local packages archive.
$PIP_LOCAL -r sources/ckan/requirements.txt

## If Python < 2.7, install ordereddict
if python -c 'import sys;sys.exit(0 if sys.version_info < (2, 7) else 1)'; then
    $PIP_LOCAL ordereddict==1.1
fi

## Install the application + plugins
cd ./sources/ckan && { { python setup.py install; }; cd -; }
cd ./sources/ckanext-datitrentinoit && { { python setup.py install; }; cd -; }

## Create configuration files in the virtualenv
if [ ! -e "$VIRTUAL_ENV"/.no-auto-conf ]; then
    ./conf/ckan/setup.sh
fi
