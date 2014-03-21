#!/bin/bash
CONF_DIR="$VIRTUAL_ENV"/etc/ckan/
mkdir -p "$CONF_DIR"
paster --plugin=ckan make-config ckan "$CONF_DIR"/etc/ckan/production.ini
