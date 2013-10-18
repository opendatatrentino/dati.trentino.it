##############################
Install Dati Trentino ckan 1.8
##############################

Installation instruction for the `dati.trentino.it`_-flavored CKAN 1.8
on Ubuntu 12.04.

.. _dati.trentino.it: http://dati.trentino.it

.. note::

    If you want to copy-paste multiple commands from a "console session" example,
    just use this to strip off the leading ``%`` characters::

        alias %=''



Setup the services
==================

.. toctree::
    :maxdepth: 2

    ./setup-postgresql
    ./setup-solr
    ./setup-appserver


Setup databases
===============

Create user:

.. code-block:: console

    # sudo -u postgres createuser -S -D -R -P ckan_user

Create database:

.. code-block:: console

    # sudo -u postgres createdb -O ckan_user ckan_default

or you can do that using SQL:

.. code-block:: sql

    CREATE USER ckan WITH PASSWORD 'pass';
    CREATE DATABASE 'ckan_default'
      WITH OWNER = 'ckan'
           ENCODING = 'UTF8'
           TABLESPACE = pg_default
           LC_COLLATE = 'en_US.UTF-8'
           LC_CTYPE = 'en_US.UTF-8'
           CONNECTION LIMIT = -1;


Setup datastore database
------------------------

Use something like this to create users and databases, and set
permissions::

    \set datastoredb 'ckan_datastore'
    \set rouser "ckan_dsr"
    \set rwuser "ckan_dsw"

    CREATE USER ckan_dsw WITH PASSWORD 'pass';
    CREATE USER ckan_dsr WITH PASSWORD 'pass';
    CREATE DATABASE :datastoredb WITH OWNER = :rwuser ENCODING = 'UTF8';

    GRANT CONNECT ON DATABASE :datastoredb TO :rouser;

    -- Connect to the target database
    \connect :datastoredb
    GRANT USAGE ON SCHEMA public TO :rouser;
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO :rouser;
    ALTER DEFAULT PRIVILEGES FOR USER :rwuser IN SCHEMA public
        GRANT SELECT ON TABLES TO :rouser;

If you put that in a script, you can run using:

.. code-block:: console

    # sudo -u postgres psql postgres -f set_permissions.sql

.. note::

    In productions, the following grants are being used:

    .. code-block:: plpgsql

        GRANT CONNECT, TEMPORARY ON DATABASE :datastoredb TO public;
        GRANT ALL ON DATABASE :datastoredb TO :rwuser;
        GRANT CONNECT ON DATABASE :datastoredb TO :rouser;



Install CKAN 1.8
================

Setup virtualenv:

.. code-block:: console

   % mkvirtualenv ckan_datitrentino
   % workon ckan_datitrentino

Install CKAN fork and requirements:

.. code-block:: console

   % pip install -e "git+ssh://git@pat-ckan-staging.spaziodati.eu/ckan@custom-dati-trentino-it#egg=ckan-dev"
   % pip install -r "$VIRTUAL_ENV"/src/ckan/requirements.txt

   % pip install -r "$VIRTUAL_ENV"/src/ckanext-archiver/pip-requirements.txt
   % pip install -r "$VIRTUAL_ENV"/src/ckanext-datastorer/requirements.txt
   % pip install -r "$VIRTUAL_ENV"/src/ckanext-harvest/requirements.txt


.. warning::
    Stuff should **not** be installed as "editable" in production,
    I have no idea on why they're doing like this..


If you experience issues with missing libxml (needed by lxml), just:

.. code-block:: console

    # apt-get install libxml2-dev libxslt1-dev

Symlink templates / assets directories:

.. code-block:: console

    % mkdir "$VIRTUAL_ENV"/etc
    % ln -s ../src/ckan/my-templates ../src/ckan/my-public "$VIRTUAL_ENV"/etc/

.. note::

    All the customizations to ckan have been committed with ``4121863d``,
    as they were just hanging around in the source::

	commit 4121863df234757b5409f7a59276d12e3a94bdc6
	Author: Samuele Santi <redshadow@hackzine.org>
	Date:   Wed Jul 17 10:46:21 2013 +0200

	    Changes by spaziodati for dati.trentino.it

    To see the changes:

    .. code-block:: console

        % git diff 4121863d


Configure CKAN
--------------

Clone the repository containing the configuration files:

.. code-block:: console

    % git clone git@pat-ckan-staging.spaziodati.eu:dati-trentino-it

Create a configuration file for passwords:

.. code-block:: console

    % cd ./dati-trentino-it/configs/
    % cp passwords.example.ini passwords.ini
    % editor passwords.ini

Create destination directory for configuration:

.. code-block:: console

    % mkdir -p "$VIRTUAL_ENV"/etc/ckan

Compile the required configuration file:

.. code-block:: console

    % ../../scripts/merge_ini.py production.ini.tpl passwords.ini > "$VIRTUAL_ENV"/etc/ckan/production.ini

Copy the other configuration files:

.. code-block:: console

    % cp -t "$VIRTUAL_ENV"/etc/ckan/ licences.json "$VIRTUAL_ENV"/src/ckan/who.ini


Install plugins
---------------

Enabled plugins:

+-------------------------+---------+---------------+-----------------------------+---------------+
| Plugin name             | Type    | Revision      | Repository                  | Notes         |
+=========================+=========+===============+=============================+===============+
| ckan_harvester          |    ?    |               |                             | [#notfound]_  |
+-------------------------+---------+---------------+-----------------------------+---------------+
| datastore               | builtin |               |                             |               |
+-------------------------+---------+---------------+-----------------------------+---------------+
| datastorer              | fork    | ``8017d9f8``  | `ckanext-datastorer`_       |               |
+-------------------------+---------+---------------+-----------------------------+---------------+
| googleanalytics         | stock   | ``6d7aa555+`` | `ckanext-googleanalytics`_  |               |
+-------------------------+---------+---------------+-----------------------------+---------------+
| harvest                 | stock   | ``994a0102+`` | `ckanext-harvest`_          |               |
+-------------------------+---------+---------------+-----------------------------+---------------+
| organizations           | builtin |               |                             |               |
+-------------------------+---------+---------------+-----------------------------+---------------+
| organizations_dataset   |    ?    |               |                             | [#notfound]_  |
+-------------------------+---------+---------------+-----------------------------+---------------+
| pat                     | custom  | ``eeb210e0``  | `ckanext-patform`_          |               |
+-------------------------+---------+---------------+-----------------------------+---------------+
| pat_categories   	  | custom  | ``06aef523``  | `ckanext-patcategories`_    |               |
+-------------------------+---------+---------------+-----------------------------+---------------+
| patstatweb_harvester    | custom  | ``6b0801c5``  | `ckanext-patstatweb`_       | [#uncertain]_ |
+-------------------------+---------+---------------+-----------------------------+---------------+
| stats                   | builtin |               |                             |               |
+-------------------------+---------+---------------+-----------------------------+---------------+


.. [#uncertain] The contained package has a different name, similar to the plugin name.
.. [#notfound] We weren't able to figure out in which package this plugin is.

.. _ckanext-datastorer: https://github.com/SpazioDati/ckanext-datastorer
.. _ckanext-googleanalytics: https://github.com/okfn/ckanext-googleanalytics
.. _ckanext-harvest: https://github.com/okfn/ckanext-harvest
.. _ckanext-patform: https://github.com/opendatatrentino/ckanext-patform
.. _ckanext-patcategories: https://github.com/opendatatrentino/ckanext-patcategories
.. _ckanext-patstatweb: https://github.com/opendatatrentino/ckanext-patstatweb


.. note:: googleanalytics has some uncommitted changes:

    .. code-block:: diff

	diff --git a/ckanext/googleanalytics/dbutil.py b/ckanext/googleanalytics/dbutil.py
	index 5029191..283d9f4 100644
	--- a/ckanext/googleanalytics/dbutil.py
	+++ b/ckanext/googleanalytics/dbutil.py
	@@ -3,6 +3,7 @@ from sqlalchemy.sql import select, text
	 from sqlalchemy import func

	 import ckan.model as model
	+from ckan.authz import Authorizer
	 from ckan.model.authz import PSEUDO_USER__VISITOR
	 from ckan.lib.base import *

.. note:: harvest has some uncommitted changes:

    .. code-block:: diff

	diff --git a/ckanext/harvest/queue.py b/ckanext/harvest/queue.py
	index 819e790..3d74a35 100644
	--- a/ckanext/harvest/queue.py
	+++ b/ckanext/harvest/queue.py
	@@ -117,6 +117,9 @@ def fetch_callback(message_data,message):

		 try:
		     obj = HarvestObject.get(id)
	+            if obj is None:
	+                log.error('Harvest object with given id is None')
	+                raise Exception
		 except:
		     log.error('Harvest object does not exist: %s' % id)
		 else:

Other plugins, installed in production but not enabled:

* ckanext-archiver (archiver)
* ckanext-patgeo (patgeo)

To install them all, you can run this, although they should already be listed in the
datitrentino CKAN fork, so you can usually skip this step:

.. code-block:: console

    % pip install -e "git+https://github.com/SpazioDati/ckanext-datastorer@8017d9f8#egg=ckanext-datastorer"
    % pip install -r "$VIRTUAL_ENV"/src/ckanext-datastorer/requirements.txt

    % pip install -e "git+https://github.com/okfn/ckanext-googleanalytics@6d7aa555#egg=ckanext-googleanalytics"
    % pip install -r "$VIRTUAL_ENV"/src/ckanext-googleanalytics/requirements.txt

    % # pip install -e "git+https://github.com/okfn/ckanext-harvest@994a0102#egg=ckanext-harvest"  # MISSING!
    % pip install -e "git+ssh://git@pat-ckan-staging.spaziodati.eu/ckanext-harvest@994a0102#egg=ckanext-harvest"
    % pip install -r "$VIRTUAL_ENV"/src/ckanext-harvest/pip-requirements.txt

    % pip install -e "git+https://github.com/opendatatrentino/ckanext-patform@eeb210e0#egg=ckanext-patform"

    % pip install -e "git+https://github.com/opendatatrentino/ckanext-patcategories@06aef523#egg=ckanext-patcategories"

    % pip install -e "git+https://github.com/opendatatrentino/ckanext-patstatweb@6b0801c5#egg=ckanext-patstatweb"


Run the server
==============

Initialize the database structure:

.. code-block:: console

    % paster --plugin=ckan db -c "$VIRTUAL_ENV"/etc/production.ini init

Rebuild the search index:

.. code-block:: console

    % paster --plugin=ckan search-index rebuild -c "$VIRTUAL_ENV"/etc/production.ini

Run the server:

.. code-block:: console

    % paster --plugin=ckan serve "$VIRTUAL_ENV"/etc/production.ini

.. todo::
    Add instructions to setup the datastore database too..

    * Need a separate db init


Production deployment
=====================

Instructions to deploy ckan 1.8 using:

* nginx
* gunicorn
* supervisor

First, install the required services:

.. code-block:: console

   # apt-get install nginx supervisor
   % pip install gunicorn

Then, configure the services (from the configuration files repository):

.. code-block:: console

    % cd ~/dati-trentino-it/
    % ./configs/ckan-1.8/nginx-conf.sh > /tmp/nginx.conf
    # mv /tmp/nginx.conf /etc/nginx/sites-available/my-env-name.conf
    # ln -s ../sites-available/my-env-name.conf /etc/nginx/sites-enabled/
    # service nginx reload

To run the server using gunicorn:

.. code-block:: console

    % gunicorn_paster --workers=4 \
        -b unix://"$VIRTUAL_ENV"/var/run/gunicorn.sock \
        "$VIRTUAL_ENV"/etc/ckan/production.ini

If everything worked, you can set up supervisor to automatically launch
the gunicorn process:

.. code-block:: console

    % ./configs/ckan-1.8/supervisor-conf.sh > /tmp/supervisor.conf
    # cat /tmp/supervisor.conf > /etc/supervisor/conf.d/my-env-name.conf
    # supervisorctl reload


.. warning::
    The CKAN documentation doens't talk about running multiple instances on the
    same server, in particular having multiple queues on rabbitmq.

    We need to dig further to see whether there is some configuration option
    or so (instance uuid..?).



Appendix
========

Complete list of dependencies
-----------------------------

This is the complete list of dependencies, obtained by running ``pip freeze --local``
in the production virtualenv::

    -e git+https://github.com/okfn/ckan.git@f221bd337db0248491aa25544585103fd196187a#egg=ckan-dev
    -e git+https://github.com/okfn/ckanext-archiver.git@de02ca516c66c594ab116107b9dfdd5cda66f1cd#egg=ckanext_archiver-dev
    -e git+https://github.com/okfn/ckanext-googleanalytics.git@6d7aa555c3b2d554fe74cc0df4186c88965a21de#egg=ckanext_googleanalytics-dev
    -e git+https://github.com/okfn/ckanext-harvest@994a0102c78000df4749813e69a18f9962130280#egg=ckanext_harvest-dev
    -e git+https://github.com/okfn/vdm.git@0554de48c6d62d152699b53b98a7589dd5c71940#egg=vdm-dev
    -e git+https://github.com/opendatatrentino/ckanext-patcategories.git@06aef5238bae80007066ca6e6c991193a5cf38cd#egg=ckanext_pat_categories-dev
    -e git+https://github.com/opendatatrentino/ckanext-patform@eeb210e08f9af82274586d38f275b09c1055c1c5#egg=ckanext_pat-dev
    -e git+https://github.com/opendatatrentino/ckanext-patgeo.git@d5433b6f6cb76af22a1388ec324a54701701ff56#egg=ckanext_patgeo-dev
    -e git+https://github.com/opendatatrentino/ckanext-patstatweb.git@6b0801c572f09190653e110be87e83677713fcb5#egg=ckanext_patstatweb-dev
    -e git://github.com/okfn/ckanext-datastorer.git@8017d9f8beb141633cf5a8c2397c51292dbdfa38#egg=ckanext_datastorer-dev
    Babel==0.9.6
    Beaker==1.6.4
    Flask==0.8
    FormAlchemy==1.4.2
    FormEncode==1.2.6
    GDAL==1.9.1
    Genshi==0.6
    Jinja2==2.6
    Mako==0.7.3
    MarkupSafe==0.15
    Pairtree==0.7.1-T
    Paste==1.7.5.1
    PasteDeploy==1.5.0
    PasteScript==1.7.5
    Pygments==1.6
    Pylons==0.9.7
    Routes==1.13
    SQLAlchemy==0.7.8
    Tempita==0.5.1
    WebError==0.10.3
    WebHelpers==1.3
    WebOb==1.0.8
    WebTest==1.4.3
    Werkzeug==0.8.3
    amqplib==1.0.2
    anyjson==0.3.3
    apachemiddleware==0.1.1
    carrot==0.10.1
    celery==2.4.2
    chardet==2.1.1
    ckanclient==0.10
    cssselect==0.7.1
    decorator==3.4.0
    distribute==0.6.24
    gdata==2.0.17
    google-api-python-client==1.0
    httplib2==0.7.7
    ipython==0.13.1
    kombu-sqlalchemy==1.1.0
    kombu==2.1.3
    lxml==3.1.0
    mechanize==0.2.5
    messytables==0.5.0
    nose==1.2.1
    oauthlib==0.4.0
    ofs==0.4.1
    openpyxl==1.5.7
    psycopg2==2.4.5
    python-dateutil==1.5
    python-gflags==2.0
    python-openid==2.2.5
    pyutilib.component.core==4.5.3
    repoze.lru==0.6
    repoze.who-friendlyform==1.0.8
    repoze.who.plugins.openid==0.5.3
    repoze.who==1.0.19
    requests-oauthlib==0.3.1
    requests==0.14.0
    simplejson==3.0.7
    solrpy==0.9.5
    sqlalchemy-migrate==0.7.2
    twython==2.9.1
    xlrd==0.9.0
    zope.interface==4.0.1
