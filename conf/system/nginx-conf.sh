#!/bin/bash

##
## Generate Nginx configuration for Ckan 2.x
##

if [ -z "$VIRTUAL_ENV" ]; then
    echo "You must be inside a VIRTUAL_ENV !"
    exit 1
fi

ENV_NAME="$( basename "$VIRTUAL_ENV" )"
BASE_DOMAIN="ckan-staging.dati.trentino.it"
DOMAIN_NAME="${ENV_NAME//_/-}.${BASE_DOMAIN}"

read -p "Base domain [$BASE_DOMAIN]: " ANSWER
if [ -n "$ANSWER" ]; then
    BASE_DOMAIN="$ANSWER"
fi

## Make sure we have the directories
mkdir -p "${VIRTUAL_ENV}"/var/{run,log}

cat <<EOF
##============================================================
## CKAN 2.x Nginx configuration
## Domain: $DOMAIN_NAME
## Environment: ${ENV_NAME}
## Generated: $( date +"%F %T %Z" )
##============================================================

## Upstream application
upstream ${ENV_NAME}_app_server {
    server unix:${VIRTUAL_ENV}/var/run/gunicorn.sock fail_timeout=0;
}

server {

    listen   80;
    server_name  ${DOMAIN_NAME};

    access_log ${VIRTUAL_ENV}/var/log/access.log combined;
    error_log  ${VIRTUAL_ENV}/var/log/error.log;

    location /      {
        satisfy any;

	proxy_pass http://${ENV_NAME}_app_server;

	## Pass headers to ckan server
	proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
	proxy_redirect off;

	## Timeouts
	proxy_connect_timeout 60s;
	proxy_read_timeout 300s;
	proxy_send_timeout 120s;

        ## No access control
	allow all;
    }
}
EOF
