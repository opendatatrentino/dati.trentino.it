Solr setup
##########

You can either use the Solr setup/configuration scripts,
or configure it by hand.


Configure Solr using scripts
============================

Install solr::

  [solr-server]# apt-get install solr-jetty openjdk-6-jdk

Clone the repository containing the scripts::

  % git clone git@pat-ckan-staging.spaziodati.eu:dati-trentino-it ~/datitrentino-tools

Configure the solr installation (one-off)::

  % cd ~/datitrentino-tools
  % ./scripts/solr-setup.sh

Define a new solr core::

  % ./scripts/solr-create.sh solr_core_name

Then, copy over the required ``schema.xml``::

  % scp .../ckan/config/solr/schema-1.4.xml /etc/solr/.../conf/schema.xml


Configure Solr manually
=======================

One-off configuration
---------------------

First, we set up jetty and prepare template configuration for solr.

Edit ``/usr/share/solr/solr.xml``::

  <solr persistent="true" sharedLib="lib">
    <cores adminPath="/admin/cores">
    </cores>
  </solr>

Move away original configuration (use as template)::

  [server]# mv /etc/solr/conf /etc/solr/conf.dist
  [server]# editor /etc/solr/conf.dist/solrconfig.xml
  ...
  <dataDir>${dataDir}</dataDir>
  ...
  [server]# rm /usr/share/solr/conf

Edit ``/etc/default/jetty``::

  NO_START=0
  JETTY_HOST=127.0.0.1  # or 0.0.0.0 for external access
  JETTY_PORT=8983

Configure manually the ``JAVA_HOME`` if you have troubles due to
JDK not found::

  JAVA_HOME=/usr/lib/jvm/java-6-openjdk-amd64/

Restart Jetty::

  [server]# invoke-rc.d jetty restart


Add a new solr "core"
---------------------

Edit ``/usr/share/solr/solr.xml``, to add the core definition::

  <solr persistent="true" sharedLib="lib">
    <cores adminPath="/admin/cores">

      <core name="ckan_datitrentino" instanceDir="ckan_datitrentino">
        <property name="dataDir" value="/var/lib/solr/data/ckan_datitrentino" />
      </core>

    </cores>
  </solr>

Create data directory::

  [server]# sudo -u jetty mkdir /var/lib/solr/data/ckan_datitrentino

Create configuration directory::

  [server]# mkdir /etc/solr/ckan_datitrentino
  [server]# cp -r /etc/solr/conf.dist /etc/solr/ckan_datitrentino/conf
  [server]# ln -s /etc/solr/ckan_datitrentino /usr/share/solr/

Copy CKAN schema in place::

  [server]# cp .../ckan/config/solr/schema-1.4.xml \
           /etc/solr/ckan_datitrentino/conf/schema.xml

Restart Jetty::

  [server]# invoke-rc.d jetty restart

Check that everything worked::

  [server]% links2 http://localhost:8983/solr
