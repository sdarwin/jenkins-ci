#!/bin/bash

set -xe

mkdir -p /etc/bcks
export timestamp=$(date -u +'%Y-%m-%d-%H-%M-%S')
rsync -ahv /etc/letsencrypt /etc/bcks/letsencrypt.$timestamp

# According to earlier notes, this step was done. Move all the previous prtest files and dirs out of the way.

rm -rf /etc/letsencrypt/renewal/prtest.cppalliance.org.conf
rm -rf /etc/letsencrypt/live/prtest.cppalliance.org/
rm -rf /etc/letsencrypt/archive/prtest.cppalliance.org/

certbot certonly --dns-cloudflare --dns-cloudflare-credentials /etc/letsencrypt/.secret \
 -d *.prtest.cppalliance.org \
 -d *.antora.prtest.cppalliance.org \
 -d *.array.prtest.cppalliance.org \
 -d *.beastdocs.prtest.cppalliance.org \
 -d *.beastdocstest.prtest.cppalliance.org \
 -d *.buffers.prtest.cppalliance.org \
 -d *.charconv.prtest.cppalliance.org \
 -d *.cppalliance.prtest.cppalliance.org \
 -d *.cppalliance-test.prtest.cppalliance.org \
 -d *.docca.prtest.cppalliance.org \
 -d *.http-proto.prtest.cppalliance.org \
 -d *.jsondocs.prtest.cppalliance.org \
 -d *.nudbdocs.prtest.cppalliance.org \
 -d *.requests.prtest.cppalliance.org \
 -d *.socks-proto.prtest.cppalliance.org \
 -d *.static-string.prtest.cppalliance.org \

certbot certonly --dns-cloudflare --dns-cloudflare-credentials /etc/letsencrypt/.secret \
-d *.prtest2.cppalliance.org \
-d *.unordered.prtest2.cppalliance.org \
-d *.url.prtest2.cppalliance.org \
-d *.vinniefalco.prtest2.cppalliance.org \
-d *.utility.prtest2.cppalliance.org \

systemctl restart nginx
