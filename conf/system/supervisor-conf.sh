#!/bin/bash

##
## Generate Supervisor configuration for Ckan 2.x
##
## Note: This assumes you're using gunicorn for running
##       the Python application, instead of paster (recommended
##       for production).
##       In order to install if, just ``pip install gunicorn``
##

if [ -z "$VIRTUAL_ENV" ]; then
    echo "You must be inside a VIRTUAL_ENV !"
    exit 1
fi

ENV_NAME="$( basename "$VIRTUAL_ENV" )"

## Make sure we have the directories
mkdir -p "${VIRTUAL_ENV}"/var/log

cat <<EOF
##============================================================
## CKAN 2.x supervisor configuration
## Environment: ${ENV_NAME}
## Generated: $( date +"%F %T %Z" )
##============================================================

[program:${ENV_NAME}]
command = ${VIRTUAL_ENV}/bin/gunicorn_paster --workers=4 -b unix://${VIRTUAL_ENV}/var/run/gunicorn.sock ${VIRTUAL_ENV}/etc/ckan/ckan.ini
user = ckan
numprocs = 1
numprocs_start=1
stdout_logfile=${VIRTUAL_ENV}/var/log/gunicorn.log
stderr_logfile=${VIRTUAL_ENV}/var/log/gunicorn.log
autostart=true
autorestart=true
startsecs=10
stopwaitsecs = 600
EOF
