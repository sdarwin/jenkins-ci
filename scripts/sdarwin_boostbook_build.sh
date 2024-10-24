#!/bin/bash

set -xe

export pythonvirtenvpath=/opt/venvboostdocs
if [ -f ${pythonvirtenvpath}/bin/activate ]; then
    source ${pythonvirtenvpath}/bin/activate
fi

mkdir -p $(pwd)/jenkins_tmp_home
export HOME=$(pwd)/jenkins_tmp_home
ls -al ${HOME}
ls -al /var/lib/jenkins/workspace

mkdir -p ${HOME}/.nvm_${REPONAME}
export NODE_VERSION=18.18.1
# The container has a pre-installed nodejs. Overwrite those again.
export NVM_BIN="${HOME}/.nvm_${REPONAME}/versions/node/v18.18.1/bin"
export NVM_DIR=${HOME}/.nvm_${REPONAME}
export NVM_INC=${HOME}/.nvm_${REPONAME}/versions/node/v18.18.1/include/node
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
export NVM_DIR=${HOME}/.nvm_${REPONAME}
. "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
. "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
. "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
export PATH="$(pwd)/node_modules/.bin:${HOME}/.nvm_${REPONAME}/versions/node/v${NODE_VERSION}/bin/:${PATH}"
node --version
npm --version
npm install diff2html-cli
which diff2html

if [ ! -d boost-root ]; then
  git clone -b master https://github.com/boostorg/boost.git boost-root
fi
cd boost-root
export BOOST_ROOT=$(pwd)
git pull
git submodule update --init libs/context
# git submodule update --init tools/boostbook
git submodule update --init tools/boostdep
git submodule update --init tools/docca
git submodule update --init tools/quickbook
rsync -av --exclude boost-root ../ tools/$REPONAME
python tools/boostdep/depinst/depinst.py ../tools/quickbook
./bootstrap.sh
./b2 headers

echo "using doxygen ; using boostbook ; using saxonhe ;" > tools/build/src/user-config.jam
./b2 -j3 tools/$REPONAME/doc/
echo "bin.v2/boostbook_catalog.xml immediately after first build"
cat bin.v2/boostbook_catalog.xml

# Build target branch
mkdir -p tools/backups
cp -rp tools/$REPONAME tools/backups/$REPONAME.pr
rm -rf tools/$REPONAME
cd tools
git clone -b develop --depth 1 https://github.com/$ORGANIZATION/$REPONAME
cd ..

echo "bin.v2/boostbook_catalog.xml immediately before second build"
cat bin.v2/boostbook_catalog.xml

./b2 -j3 tools/$REPONAME/doc/

echo "bin.v2/boostbook_catalog.xml immediately after second build"
cat bin.v2/boostbook_catalog.xml

mkdir diff
cd diff
git init
git config user.name "Your Name"
git config user.email "you@example.com"
cp -rp ../tools/$REPONAME/doc/html .
git add -f ./html
git commit -m "before"
rm -r ./html
cp -rp ../tools/backups/$REPONAME.pr/doc/html .
git add -f ./html
if git commit -m "after"; then
    diff2html -t "diff with develop branch" --cs light -s side -F ./diff.html -- -M HEAD~1
else
    echo "No difference in this commit" > diff.html
fi

# Restore first build, in order to upload
cd ..
mv tools/$REPONAME tools/$REPONAME.targetbranch
mv tools/backups/$REPONAME.pr tools/$REPONAME

# Copy in the diff, so that it will be uploaded
cp diff/diff.html tools/$REPONAME/doc/html/
