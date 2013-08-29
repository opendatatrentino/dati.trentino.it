#!/bin/bash

cd "$( dirname "$BASH_SOURCE" )"

if [ ! -e keys.ini ]; then
    ./keys.ini.sh
fi

../../scripts/merge_ini.py production.ini.tpl keys.ini passwords.ini > production.ini
