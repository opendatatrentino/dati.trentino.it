Installation instructions
#########################

Requirements:

* Install PostgreSQL (and create a database)
* Install Solr (with the appropriate schema)


Clone the master repository
===========================

First, we need to SSH into the destination machine with ssh agent forward,
in order to be able to clone the "private" repository::

    ssh -A dati.trentino.it

In alternative, we can generate a SSH key for the server and add it as a
read-only "deployment key" to the GitHub repo.

Then, clone the repository::

    git clone ssh://git@github.com/trentorise/dati.trentino.it ~/dati.trentino.it
    cd ~/dati.trentino.it
    git submodule init
    git submodule update


.. note::
    We will need to put the Solr configuration file on the Solr server too.


Prepare the environment
=======================

We need a user + all the required dependencies in order to run ckan.

First, we want to install a recent version of pip::

    git clone https://github.com/pypa/pip
    cd pip
    git checkout 1.4.1
    python setup.py install --user


Also, remember to add ``~/.local/bin`` to your ``$PATH``::

    echo 'export PATH="${HOME}/.local/bin:${PATH}"' >> ~/.bashrc

Install virtualenv / virtualenvwrapper::

    pip install --user virtualenv virtualenvwrapper
    echo 'source $HOME/.local/bin/virtualenvwrapper_lazy.sh' >> ~/.bashrc


Optional - custom Python version
--------------------------------

If Python 2.7 is not available, it's strongly suggested to use pyenv_
to install it.

.. _pyenv: https://github.com/yyuu/pyenv


Create a virtualenv for installing ckan
=======================================

::

    mkvirtualenv dti-production


Install ckan and dependencies
=============================

.. code-block:: bash

    workon dti-production

    mkdir ~/sources && cd ~/sources
    BRANCH=dti2x-production
    for repo in ckan ckanext-datitrentinoit; do
        git clone https://github.com/opendatatrentino/"${repo}".git
        cd $repo && {
            { git fetch --tags && \
              git checkout "$BRANCH" && \
              if [ -e requirements.txt ]; then
                  pip install -r requirements.txt;
              fi };
            cd -
        }
    done



Create configuration file
=========================

With the virtualenv active, launch::

    ~/dati.trentino.it/conf/ckan/setup.sh

to copy the configuration files in the virtualenv folder.

A ``compile.sh`` script will be generated in order to recompile
the configuration file at need.

Then, change passwords in the ``.passwords.ini`` file and re-run
``compile.sh`` to generate the final configuration file.


Import database dump
====================

- **todo:** link to a migration 1.8 -> 2.2 page
- **todo:** import dump in postgresql
- **todo:** reindex stuff in solr


Configure services
==================

- **todo:** make supervisor launch gunicorn_paster
- **todo:** put nginx in front of supervisor

  - **todo:** can we serve static files directly from nginx?
  - **todo:** otherwise, can we put a long cache in front of the prefix
    for static files, in order to speed up requests?


Running with sentry
-------------------

It would be really nice to use Sentry_ for logging the errors + tracebacks.
There is a raven_ plugin for pylons that should work, but this requires
creating a new Python script that imports the CKAN WSGI application
and adds the appropriate middleware, plus some customizations in the paster
configuration file.
