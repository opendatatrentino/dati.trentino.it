##############################
Install Dati Trentino ckan 1.8
##############################













**DEPRECATED**















Installation instruction for the `dati.trentino.it`_-flavored CKAN 1.8

.. _dati.trentino.it: http://dati.trentino.it


Install ubuntu 12.04
====================

Install a standard ubuntu 12.04 server system.

.. note:: We use 12.04 as it is the current LTS.

Install PostgreSQL (9.1 or later is recommended)::

  [server]# apt-get install postgresql

Install solr::

  [server]# apt-get install solr-jetty openjdk-6-jdk

Install application dependencies::

  [server]# apt-get install python-dev flibpq-dev git libxml2-dev libxslt1-dev


PostgreSQL Configuration
========================

See: :doc:`/datitrentino-18/setup-postgresql`



(optional) PostgreSQL on a separate machine
-------------------------------------------

If you want to install PostgreSQL on a separate machine, you have to make
it reachable from the outside.

Change ``postgresql.conf``::

  listen_addresses = '*'

Change ``pg_hba.conf``::

  host    all             all             192.168.0.0/16          md5

Set password for the ``postgres`` user::

  [server]# su - postgres -c psql
  psql (9.1.9)
  Type "help" for help.

  postgres=# alter user postgres password 'pgadmin';
  ALTER ROLE
  postgres=# \q


Tweak PostgreSQL resources limit
--------------------------------

In order to, for example, dump large datastore databases, you have to tweak
some PostgreSQL/system configuration.

Edit ``/etc/postgresql/9.1/main/postgresql.conf``::

  max_locks_per_transaction = 128
  max_connections = 100

Then raise the maximum amount of shared memory (512Mb in this case).
Edit ``/etc/sysctl.conf``::

  kernel.shmmax=536870912

And then reload the sysctl configuration::

  sysctl -p /etc/sysctl.conf

See also `Managing Kernel Resources`_.

.. _Managing Kernel Resources: http://www.postgresql.org/docs/9.1/static/kernel-resources.html


Configure SOLR using scripts
============================

Clone the repository containing the scripts::

  % git clone git@pat-ckan-staging.spaziodati.eu:dati-trentino-it ~/datitrentino-tools

Configure the solr installation (one-off)::

  % cd ~/datitrentino-tools
  % ./scripts/solr-setup.sh

Define a new solr core::

  % ./scripts/solr-create.sh solr_core_name

Then, copy over the required ``schema.xml``.


Configure SOLR (alternate way)
==============================

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


Install Python-related dependencies
===================================

Install setuptools::

  [server]# apt-get install python-setuptools

Install a recent version of pip::

  [server]% git clone git://github.com/pypa/pip pip
  [server]% cd pip
  [server]% python setup.py install --user

Add ``~/.local/bin`` to ``$PATH``::

  [server]% echo >> .bashrc 'export PATH="${HOME}/.local/bin:${PATH}"'

Make sure to load stuff from the new ``$PATH``::

  [server]% source .bashrc
  [server]% hash -r

Install virtualenv and virtualenvwrapper::

  [server]% pip install --user virtualenv virtualenvwrapper
  [server]% echo >> .bashrc 'source "${HOME}"/.local/bin/virtualenvwrapper_lazy.sh'
  [server]% source .bashrc


Install CKAN
============

Setup virtualenv::

   [server]% mkvirtualenv ckan_datitrentino
   [server]% workon ckan_datitrentino

Install CKAN fork and requirements::

   pip install -e git+ssh://git@pat-ckan-staging.spaziodati.eu/ckan@custom-dati-trentino-it#egg=ckan-dev
   pip install -r "$VIRTUAL_ENV"/src/ckan/requirements.txt

   pip install -r "$VIRTUAL_ENV"/src/ckanext-archiver/pip-requirements.txt
   pip install -r "$VIRTUAL_ENV"/src/ckanext-datastorer/requirements.txt
   pip install -r "$VIRTUAL_ENV"/src/ckanext-harvest/requirements.txt

If you experience issues with missing libxml (needed by lxml), just::

   [server]# apt-get install libxml2-dev libxslt1-dev

Configure services::

  mkdir $VIRTUAL_ENV/etc
  cp $VIRTUAL_ENV/src/ckan/who.ini "$VIRTUAL_ENV"/etc/
  ln -s ../src/ckan/my-templates ../src/ckan/my-public "$VIRTUAL_ENV"/etc/
  ln -s ../src/ckan/dati-trentino-it/licences.json "$VIRTUAL_ENV"/etc/

And copy the main ``.ini`` configuration in ``$VIRTUAL_ENV/etc/production.ini``,
then change configuration values for database/indexer.


Configure CKAN
--------------

Clone the repository containing the configuration files::

  % git clone git@pat-ckan-staging.spaziodati.eu:dati-trentino-it ~/datitrentino-tools

Create a configuration file for passwords::

  % cp ~/datitrentino-tools/passwords.example.ini /path/to/passwords.ini
  % editor /path/to/passwords.ini

Compile the required configuration file::

  % pip install -U config-gen
  % confgen-render-file ./configs/production.ini \
      --context=passwords:ini:/path/to/passwords.ini \
      > "$VIRTUAL_ENV"/etc/production.ini


Run the server
==============

Rebuild the search index::

  paster --plugin=ckan search-index rebuild -c "$VIRTUAL_ENV"/etc/production.ini

Run the server::

  paster --plugin=ckan serve "$VIRTUAL_ENV"/etc/production.ini


.. todo::
   Add more deployment instructions.
   For example, we could use gunicorn instead of paster.
