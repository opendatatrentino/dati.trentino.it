#!/usr/bin/env python

"""
Scripts to upgrade customizations in the Ckan database
imported from 1.8-dti to 2.x (vanilla).

We need to:

* Mark all the imported groups as organizations

* Set ``is_organization = TRUE``

* Rename all the organizations to prevent naming conflicts

* Add the ``org-`` prefix

* Create a dummy revision, to be used for linking with all the
  new stuff

* Export tags from the "category_vocab" vocabulary as groups

  * Create records in ``group`` / ``group_revision``

  * Create relations between datasets and groups, in the
    ``member`` table.

  * Delete old tags + vocabulary + relations


We can also:

* Clean up the ``celery_*`` and ``kombu_*`` tables

"""

from __future__ import print_function

from ConfigParser import RawConfigParser
import datetime
import os
import re
import sys
import urlparse
import uuid

import psycopg2
import psycopg2.extras


SIMULATION_MODE = False


class DbMigrationApp(object):
    def __init__(self, conf_file_name):
        self.conf_file_name = conf_file_name
        self.connection = self.get_postgres_connection()

    def get_postgres_conf(self):
        ## Read ``[app:main]sqlalchemy.url``
        cfp = RawConfigParser()
        cfp.read(self.conf_file_name)
        sqlalchemy_url = cfp.get('app:main', 'sqlalchemy.url')
        u = urlparse.urlparse(sqlalchemy_url)
        assert u.scheme == 'postgresql'
        return {
            'host': u.hostname,
            'port': u.port or 5432,
            'user': u.username,
            'password': u.password,
            'database': filter(None, u.path.split('/'))[0],
        }

    def get_postgres_connection(self):
        return psycopg2.connect(**self.get_postgres_conf())

    def get_cursor(self):
        """Return a psycopg DictCursor"""
        return self.connection.cursor(
            cursor_factory=psycopg2.extras.DictCursor)

    def cursor_context(self):
        return CursorContext(self.get_cursor())


class CursorContext(object):
    def __init__(self, cursor):
        self.cursor = cursor

    def __enter__(self):
        self.cursor.execute("BEGIN")
        return self.cursor

    def __exit__(self, *a):
        ## todo: rollback if an exception occurred too!
        if SIMULATION_MODE:
            self.cursor.execute("ROLLBACK")
        else:
            self.cursor.execute("COMMIT")
        self.cursor.close()


def log_object(name, obj):
    print("\033[1m{0}:\033[0m {1}".format(name.capitalize(), obj))


def gen_insert_query(table, obj):
    base_query = "INSERT INTO \"{table}\" ({fields}) VALUES ({values});"
    fields, values = zip(*((k, '%({0})s'.format(k)) for k in obj))
    query = base_query.format(
        table=table,
        fields=', '.join(fields),
        values=', '.join(values))
    return query


if len(sys.argv) >= 2:
    cfg_file_name = sys.argv[1]
else:
    cfg_file_name = os.path.join(os.environ['VIRTUAL_ENV'],
                                 'etc', 'ckan', 'production.ini')

db = DbMigrationApp(cfg_file_name)


##-----------------------------------------------------------------------------
## Create a revision for all the changes we are going to make

MIGRATION_REVISION_UUID = str(uuid.uuid4())
MIGRATION_DATE = datetime.datetime.now()

print("Creating a revision for all the new objects")
print("    Revision id: {0}".format(MIGRATION_REVISION_UUID))
with db.cursor_context() as cur:
    data = {
        'id': MIGRATION_REVISION_UUID,
        'timestamp': MIGRATION_DATE,
        'author': '**migration-script**',
        'message': 'Custom data migration, from 1.8-dti to 2.x',
        'state': 'active',
    }
    query = gen_insert_query('revision', data)
    cur.execute(query, data)


##-----------------------------------------------------------------------------
## Fix the existing groups
## - They're all organizations -> change their type
## - We need to make sure they're linked correctly with datasets
##   - We need to update the "owner_org" field in the datasets

# Probably the best way is to:
#  - export organizations
#  - export membershipts
#  - apply changes on datasets one-by-one

print("Marking old groups as organizations")
with db.cursor_context() as cur:
    cur.execute("""
    UPDATE "group" SET
        "is_organization" = TRUE,
        "type" = 'organization';
    """)
    print("    " + cur.statusmessage)
    cur.execute("""
    UPDATE "group_revision" SET
        "is_organization" = TRUE,
        "type" = 'organization';
    """)
    print("    " + cur.statusmessage)

print("Fixing relationships (add capacity='organization')")
with db.cursor_context() as cur:
    cur.execute("""
    UPDATE member SET capacity='organization'
    WHERE table_name='package' AND group_id IN (
        SELECT id FROM "group" WHERE is_organization=TRUE
    );
    """)
    print("    " + cur.statusmessage)
    cur.execute("""
    UPDATE member_revision SET capacity='organization'
    WHERE table_name='package' AND group_id IN (
        SELECT id FROM "group_revision" WHERE is_organization=TRUE
    );
    """)
    print("    " + cur.statusmessage)

print("Updating owner organization for packages")
with db.cursor_context() as cur:
    cur.execute("""
    UPDATE "package" AS p SET owner_org=(
        SELECT group_id FROM "member"
        WHERE table_name='package'
              AND table_id=p.id
              AND state='active'
              LIMIT 1
    );
    """)
    print("    " + cur.statusmessage)
    cur.execute("""
    UPDATE "package_revision" AS p SET owner_org=(
        SELECT group_id FROM "member_revision"
        WHERE table_name='package'
              AND table_id=p.id
              AND state='active'
              LIMIT 1
    );
    """)
    print("    " + cur.statusmessage)

print("Collecting organization names")
org_names = set()
with db.cursor_context() as cur:
    cur.execute("""
    SELECT name FROM "group"
    WHERE is_organization = TRUE;
    """)
    for row in cur.fetchall():
        org_names.add(row['name'])
print("    Found {0} organizations".format(len(org_names)))


##-----------------------------------------------------------------------------
## Extract all the tags from the "category_vocab" vocabulary

print("Converting category tags -> groups")
with db.cursor_context() as cur:
    cur.execute("""
    SELECT * FROM tag
    WHERE vocabulary_id = (
        SELECT id FROM vocabulary
        WHERE name='category_vocab'
    );
    """)
    print("    " + cur.statusmessage)

    for tag in cur.fetchall():
        print("Processing tag: {0}".format(tag['name']))

        group_id = str(uuid.uuid4())

        print("    Creating group: {0}".format(group_id))

        cat_name = re.sub(r"[^A-Za-z0-9]+", "-", tag['name'].lower())
        if cat_name in org_names:
            cat_name = 'cat-{0}'.format(cat_name)

        ## Create group/group_revision
        group_data = {
            'id': group_id,
            'name': cat_name,
            'title': tag['name'],
            'created': MIGRATION_DATE,
            'state': 'active',
            'revision_id': MIGRATION_REVISION_UUID,
            'type': 'group',
            'approval_status': 'approved',
            'image_url': '',
            'is_organization': False,
        }
        group_revision_data = group_data.copy()
        group_revision_data.update({
            'description': '',
            'continuity_id': group_id,
            'expired_id': '',
            'revision_timestamp': MIGRATION_DATE,
            'expired_timestamp':
            datetime.datetime(9999, 12, 31, 0, 0, 0),
            'current': True,
        })

        ## Create "group" and "group_revision"
        with db.cursor_context() as cur3:
            query = gen_insert_query('group', group_data)
            cur3.execute(query, group_data)
            query = gen_insert_query('group_revision',
                                     group_revision_data)
            cur3.execute(query, group_revision_data)

        ## Find dataset relations
        with db.cursor_context() as cur2:
            cur2.execute(
                """
                SELECT * FROM package_tag WHERE tag_id = %(tag_id)s
                """,
                dict(tag_id=tag['id']))
            for tag_package_rel in cur2.fetchall():
                print("    Relation: package: {0}"
                      "".format(tag_package_rel['package_id']))

                ## Create "membership" record
                with db.cursor_context() as cur3:
                    data = {
                        'id': str(uuid.uuid4()),
                        'table_name': 'package',
                        'table_id': tag_package_rel['package_id'],
                        'group_id': group_id,
                        'state': 'active',
                        'capacity': 'public',
                    }
                    rev_data = data.copy()
                    rev_data.update({
                        'revision_id': MIGRATION_REVISION_UUID,
                        'continuity_id': data['id'],
                        'expired_id': '',
                        'revision_timestamp': MIGRATION_DATE,
                        'expired_timestamp':
                        datetime.datetime(9999, 12, 31, 0, 0, 0),
                        'current': True,
                    })
                    query = gen_insert_query('member', data)
                    cur3.execute(query, data)
                    query = gen_insert_query('member_revision', rev_data)
                    cur3.execute(query, rev_data)

with db.cursor_context() as cur:
    cur.execute("""
    TRUNCATE TABLE kombu_message CASCADE;
    TRUNCATE TABLE kombu_queue CASCADE;
    TRUNCATE TABLE task_status CASCADE;
    DELETE FROM related WHERE title='Visualizzatore JSON'
    """)
