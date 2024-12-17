#!/bin/bash

set -xe

export pythonvirtenvpath=/opt/venvboostdocs
if [ -f ${pythonvirtenvpath}/bin/activate ]; then
    source ${pythonvirtenvpath}/bin/activate
fi 

if [[ "${JOB_BASE_NAME}" =~ PR ]]; then
    BOOST_BRANCH="develop"
else
    BOOST_BRANCH=${BRANCH_NAME}
fi 

if [ ! -d boost-root ]; then
  git clone -b ${BOOST_BRANCH} https://github.com/boostorg/boost.git boost-root
fi
cd boost-root
export BOOST_ROOT=$(pwd)
git pull
git submodule update --init libs/context
git submodule update --init libs/json
git submodule update --init tools/boostbook
git submodule update --init tools/boostdep
# git submodule update --init tools/docca
rsync -av --delete --exclude boost-root --exclude docstarget ../ tools/docca
git submodule update --init tools/quickbook
rsync -av --exclude boost-root ../ tools/$REPONAME
python tools/boostdep/depinst/depinst.py ../tools/quickbook
# Is depinst overwriting the library's folder? Rerun rsync.
rsync -av --delete --exclude boost-root --exclude docstarget ../ tools/docca
./bootstrap.sh
./b2 headers

echo "using doxygen ; using boostbook ; using saxonhe ;" > tools/build/src/user-config.jam

./b2 -j3 tools/$REPONAME/example/
./b2 -j3 tools/$REPONAME/example//boostrelease
