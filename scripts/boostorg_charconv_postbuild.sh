#!/bin/bash

set -xe
pwd
sourcefile=boost-root/libs/charconv/doc/html/charconv.html
destfile=boost-root/libs/charconv/doc/html/index.html

if [ ! -f $destfile ]; then
    cp $sourcefile $destfile
fi
