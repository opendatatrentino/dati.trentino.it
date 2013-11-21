#!/bin/bash

if [ -z "$VIRTUAL_ENV" ]; then
    echo "You must run this inside a virtualenv"
    exit 1
fi

cd "$( dirname "$0" )"


CONFDIR="$VIRTUAL_ENV"/etc/ckan
mkdir -p "$CONFDIR"

if [ ! -e "$CONFDIR"/.keys.ini ]; then
    echo "Generating fresh keys..."
    cat > "$CONFDIR"/.keys.ini <<EOF
[app:main]
beaker.session.secret = $( dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 )
app_instance_uuid = {$( uuidgen ))}
EOF
fi

if [ ! -e "$CONFDIR"/.passwords.ini ]; then
    echo "Creating dummy passwords file..."
    cp passwords.example.ini "$CONFDIR"/.passwords.ini
fi

cp production.ini.tpl "$CONFDIR"/.production.ini.tpl
cp who.ini "$CONFDIR"/who.ini
cp licenses.json "$CONFDIR"/licenses.json

cat > "$CONFDIR"/compile.sh <<EOF_OF_SCRIPT
#!/bin/bash

cd "\$( dirname "\$BASH_SOURCE" )"

INPUT=".production.ini.tpl .keys.ini .passwords.ini"
OUTPUT=production.ini

python - \$INPUT > \$OUTPUT <<EOF
import sys
from ConfigParser import RawConfigParser

if __name__ == '__main__':
    rc = RawConfigParser()
    rc.read(sys.argv[ 1:])
    rc.write(sys.stdout)
EOF

EOF_OF_SCRIPT

chmod +x "$CONFDIR"/compile.sh
"$CONFDIR"/compile.sh

echo "Done. Ckan configuration is in ${CONFDIR}"
