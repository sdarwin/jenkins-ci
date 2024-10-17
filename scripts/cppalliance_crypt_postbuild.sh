#!/bin/bash

set -xe
pwd
sourcefile=boost-root/libs/crypt/doc/html/crypt.html
destfile=boost-root/libs/crypt/doc/html/index.html

if [ ! -f $destfile ]; then
    cp $sourcefile $destfile
fi
