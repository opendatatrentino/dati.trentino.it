#!/bin/bash

## Install CKAN dependencies

if [ -z "$VIRTUAL_ENV" ]; then
    echo "You must run this inside a virtualenv."
    exit 1
fi


mkdir -p "$VIRTUAL_ENV"/src/
cd "$VIRTUAL_ENV"/src/

GITHUB=https://github.com/
#GITHUB=ssh://git@github.com/

BRANCH=dti2x-production
#BRANCH=dti2x-develop


function clone_repo() {
    REPO=$1
    DEST=$2
    if [ ! -d "$DEST" ]; then
	echo ">>> Cloning repository $REPO (branch: $BRANCH)"
	git clone -b $BRANCH ${GITHUB}${REPO} ${DEST}
    else
	echo ">>> Updating existing repository $REPO (branch: $BRANCH)"
	cd ${DEST} && {
	    git fetch origin
	    git checkout origin/$BRANCH
	    cd -
	}
    fi
    echo ""
}

function install_python_project() {
    SRCDIR=$1
    echo ">>> Installing Python project: $SRCDIR"
    cd $SRCDIR && {
	python setup.py install
	if [ -e requirements.txt ]; then
	    pip install -r requirements.txt
	fi
	if [ -e pip-requirements.txt ]; then
	    pip install -r pip-requirements.txt
	fi
	cd -
    }
    echo
}



ODT_REPOS="ckan ckanclient ckanext-datitrentinoit ckanext-harvest ckanext-patstatweb"

for reponame in $ODT_REPOS; do
    clone_repo opendatatrentino/${reponame}.git $reponame
    install_python_project $reponame
done
