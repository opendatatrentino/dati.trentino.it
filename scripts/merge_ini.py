#!/usr/bin/env python

"""
Merge .ini files
"""

import sys
from ConfigParser import RawConfigParser

if __name__ == '__main__':
    rc = RawConfigParser()
    rc.read(sys.argv[1:])
    rc.write(sys.stdout)
