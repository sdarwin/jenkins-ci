#!/bin/bash

set -xe
echo "PRTEST=prtest2" >> jenkinsjobinfo.sh
echo "ONLY_BUILD_ON_DOCS_MODIFICATION=true" >> jenkinsjobinfo.sh
