CKAN configuration files
########################

This directory contains:

* ``keys.ini.sh`` Script used to generate the ``keys.ini`` file, containing
  random-generated keys.

* ``licences.default.json`` The default licences file for ckan

* ``licences.json`` The custom licences file for datitrentino ckan

* ``passwords.example.ini`` Example passwords file, to be copied as ``passwords.ini``
  and configured

* ``production.ini.tpl`` Base template for the ckan configuration file

* ``who.ini`` Configuration for repoze.who, taken from ckan sources


Building configuration files
============================

Copy and configure the passwords file::

    % cp passwords.example.ini passwords.ini
    % editor passwords.ini

Compile all the configuration files together::

    % ./compile.sh

Copy over the configuration files::

    % mkdir -p "$VIRTUAL_ENV"/etc/ckan
    % cat production.ini > "$VIRTUAL_ENV"/etc/ckan/production.ini
    % cp licences.json who.ini "$VIRTUAL_ENV"/etc/ckan/
