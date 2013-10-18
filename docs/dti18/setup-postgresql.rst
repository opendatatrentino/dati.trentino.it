PostgreSQL setup
################

Install PostgreSQL (9.1 or later is recommended)::

  [pgsql-server]# apt-get install postgresql postgresql-contrib

PostgreSQL on a separate machine
--------------------------------

If you want to install PostgreSQL on a separate machine, you have to make
it reachable from the outside.

Change ``postgresql.conf``::

  listen_addresses = '*'

Change ``pg_hba.conf`` to add something like this::

  host    all    all    192.168.0.0/16    md5

Set password for the ``postgres`` user if you want to administer postgresql
from another machine::

  [pgsql-server]# su - postgres -c psql
  psql (9.1.9)
  Type "help" for help.

  postgres=# ALTER USER postgres PASSWORD 'pgadmin';
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

  [pgsql-server]# sysctl -p /etc/sysctl.conf

See also `Managing Kernel Resources`_.

.. _Managing Kernel Resources: http://www.postgresql.org/docs/9.1/static/kernel-resources.html
