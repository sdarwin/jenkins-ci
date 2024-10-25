#!/bin/bash

set -xe
pwd
sourcefile=boost-root/tools/boostlook/doc/html/specimen.html
destfile=boost-root/tools/boostlook/doc/html/index.html

if [ ! -f $destfile ]; then
    cp $sourcefile $destfile
fi
