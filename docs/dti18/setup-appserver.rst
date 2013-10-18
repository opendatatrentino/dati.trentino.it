Application server setup
########################

Install application dependencies::

  [app-server]# apt-get install python-dev libpq-dev git libxml2-dev libxslt1-dev

Install Python tools
--------------------

Install setuptools::

  [app-server]# apt-get install python-setuptools

Install a recent version of pip::

  [app-server]% git clone git://github.com/pypa/pip pip
  [app-server]% cd pip
  [app-server]% python setup.py install --user

Add ``~/.local/bin`` to ``$PATH``::

  [app-server]% echo >> .bashrc 'export PATH="${HOME}/.local/bin:${PATH}"'

Make sure to load stuff from the new ``$PATH``::

  [app-server]% source .bashrc
  [app-server]% hash -r

Install virtualenv and virtualenvwrapper::

  [app-server]% pip install --user virtualenv virtualenvwrapper
  [app-server]% echo >> .bashrc 'source "${HOME}"/.local/bin/virtualenvwrapper_lazy.sh'
  [app-server]% source .bashrc
