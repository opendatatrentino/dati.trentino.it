#!/bin/bash

## Configure a newly-created SOLR setup

if [ -e /usr/share/solr/solr.xml ]; then
    cp /usr/share/solr/solr.xml /usr/share/solr/solr.xml.dist
fi

mkdir /usr/share/solr/solr.xml.d

cat > /usr/share/solr/solr.xml.d/00_header.conf <<EOF
<solr persistent="true" sharedLib="lib">
    <cores adminPath="/admin/cores">
EOF

cat > /usr/share/solr/solr.xml.d/99_footer.conf <<EOF
    </cores>
</solr>
EOF

## Compile /usr/share/solr/solr.xml
cat /usr/share/solr/solr.xml.d/*.conf > /usr/share/solr/solr.xml

## Prepare template configuration
mv /etc/solr/conf /etc/solr/conf.dist

sed 's@<dataDir>.*</dataDir>@<dataDir>${dataDir}</dataDir>@' \
    -i /etc/solr/conf.dist/solrconfig.xml

cat >> /etc/default/jetty <<EOF
NO_START=0
JETTY_HOST=127.0.0.1
JETTY_PORT=8983
JAVA_HOME=/usr/lib/jvm/java-6-openjdk-amd64/
EOF

invoke-rc.d jetty restart
