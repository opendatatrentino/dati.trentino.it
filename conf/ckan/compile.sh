#!/bin/bash

cd "$( dirname "$BASH_SOURCE" )"

if [ ! -e keys.ini ]; then
    ./keys.ini.sh
fi

INPUT="production.ini.tpl keys.ini passwords.ini"
OUTPUT=production.ini

python - $INPUT > $OUTPUT <<EOF
import sys
from ConfigParser import RawConfigParser

if __name__ == '__main__':
    rc = RawConfigParser()
    rc.read(sys.argv[ 1:])
    rc.write(sys.stdout)
EOF
