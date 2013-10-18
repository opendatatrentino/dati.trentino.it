#################################
Clone dati.trentino.it (ckan 1.8)
#################################

Follow :doc:`the installation guide </datitrentino-18/index>`.

Clone database
==============

On the production server::

  prod$ sudo -u postgres -H pg_dump patdbckan -f /tmp/patdbckan.backup -Fc

Copy in some way from prod to dev machines::

  work$ scp prod-server:/tmp/patdbckan.backup /tmp/patdbckan.backup
  work$ scp /tmp/patdbckan.backup dev-server:/tmp/patdbckan.backup

On the development server::

  dev# sudo -u postgres -H pg_restore --dbname "ckan_datitrentino" /tmp/patdbckan.backup


Rebuild the solr index::

  (venv)% paster --plugin=ckan search-index -c $VIRTUAL_ENV/etc/ckan.ini rebuild
