#!/bin/bash 
set -xe 
PREVIEWMESSAGE="A preview of the cppalliance website is available at https://${CHANGE_ID}.${DNSREPONAME}.prtest.cppalliance.org"
curl -X POST -H 'Content-type: application/json' --data  "{\"text\":\"$PREVIEWMESSAGE\"}"  ${CPPAL_SLACK_WEBHOOK}
