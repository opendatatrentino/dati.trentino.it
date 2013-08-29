#!/bin/bash

## Create configuration for a new SOLR core

CORE_NAME="$1"
if [ -z "$CORE_NAME" ]; then
    echo "Usage: $0 <core_name>"
    exit 1
fi

cat >> /usr/share/solr/solr.xml.d/20_core_"$CORE_NAME".conf <<EOF
        <core name="${CORE_NAME}" instanceDir="${CORE_NAME}">
            <property name="dataDir" value="/var/lib/solr/data/${CORE_NAME}" />
        </core>
EOF

cat /usr/share/solr/solr.xml.d/*.conf > /usr/share/solr/solr.xml

sudo -u jetty mkdir /var/lib/solr/data/"$CORE_NAME"

mkdir /etc/solr/"$CORE_NAME"
cp -r /etc/solr/conf.dist/ /etc/solr/"$CORE_NAME"/conf
ln -s /etc/solr/"$CORE_NAME"/ /usr/share/solr/

echo "Done. Now replace /etc/solr/${CORE_NAME}/conf/schema.xml"
echo "with your custom schema and restart jetty."
