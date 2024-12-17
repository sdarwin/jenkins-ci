#!/bin/bash

set -xe
echo "export PRTEST=prtest" >> jenkinsjobinfo.sh
echo "export PATH_TO_DOCS=tools/docca/example" >> jenkinsjobinfo.sh
