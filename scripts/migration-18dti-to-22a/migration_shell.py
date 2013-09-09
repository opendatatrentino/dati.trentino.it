#!/usr/bin/env python

# Run this as::
#
#     % ipython -i migration_shell.py
#
# or::
#
#     % python -i migration_shell.py

import os
import re
import uuid

import psycopg2
import psycopg2.extras


## todo: put this in a configuration file
connection = psycopg2.connect(
    host='ckan-db.local',
    port=5432,
    user='ckan',
    password='pass',
    database='ckan_datitrentino_20',
)

def get_cursor():
    """Return a psycopg DictCursor"""
    return connection.cursor(cursor_factory=psycopg2.extras.DictCursor)
