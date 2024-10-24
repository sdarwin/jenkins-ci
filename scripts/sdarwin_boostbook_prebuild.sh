#!/bin/bash

set -xe
echo "export PRTEST=prtest2" >> jenkinsjobinfo.sh
echo "export PATH_TO_DOCS=tools/boostbook/doc" >> jenkinsjobinfo.sh
echo "export DIFF2HTML=true" >> jenkinsjobinfo.sh
