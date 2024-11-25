#!/bin/bash

set -xe
echo "export PRTEST=prtest" >> jenkinsjobinfo.sh
echo "export ONLY_BUILD_ON_DOCS_MODIFICATION=true" >> jenkinsjobinfo.sh

git submodule update --init doc/docca
cd doc
chmod 755 makeqbk.sh
./makeqbk.sh
cd ..
sed -i 's,path-constant TEST_MAIN : $(BOOST_ROOT)/boost/beast/_experimental/unit_test/main.cpp ;,,' Jamroot

