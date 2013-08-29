#!/bin/bash

cat > keys.ini <<EOF
[app:main]
beaker.session.secret = $( dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 )
app_instance_uuid = {$( uuidgen ))}
EOF
