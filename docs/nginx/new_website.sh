#!/bin/bash

# Creates an nginx vhost. Adds a DNS entry in cloudflare. Requests a let's encrypt certificate.
# Run the script similarly to this:
# ./new_website.sh develop.nudb.cpp.al

set -e

website=$1

if [ -z "$website" ]; then
    echo "Please set website value. Exiting."
    exit 1
fi

echo " "
echo "STEP 1: Creating DNS entry."
echo " "

website=$1
dns_part1=$(echo $website | cut -d "." -f 1)
dns_part2=$(echo $website | cut -d "." -f 2)
dns_cname_record="$dns_part1.$dns_part2"

. ~/.config/cloudflare_credentials

curl --request POST \
  --url https://api.cloudflare.com/client/v4/zones/$dns_cloudflare_zoneid/dns_records \
  --header "Content-Type: application/json" \
  --header "X-Auth-Email: $dns_cloudflare_email" \
  --header "Authorization: Bearer $dns_cloudflare_api_token" \
  --data '{
  "content": "jenkins.cppalliance.org.",
  "name": "'${dns_cname_record}'",
  "type": "CNAME",
  "proxied": false
}'

sleep 10

echo " "
echo "STEP 2: Create nginx site"
echo " "

cp -i base_website_template /etc/nginx/sites-available/$website
sed -i "s/_website_name_/$website/" /etc/nginx/sites-available/$website
ln -s /etc/nginx/sites-available/$website /etc/nginx/sites-enabled/$website
systemctl reload nginx

sleep 2

echo " "
echo "STEP 3: Requesting cert"
echo " "

certbot certonly --webroot-path /var/www/letsencrypt --webroot -d $website

echo " "
echo "STEP 3 continued: MODIFYING RENEWAL FILE"
echo " "

renewalfile=/etc/letsencrypt/renewal/${website}.conf
if ! grep try-reload-or-restart $renewalfile ; then
   sed -i 's/\[renewalparams\]/[renewalparams]\nrenew_hook = systemctl try-reload-or-restart nginx/' $renewalfile
fi

echo " "
echo "STEP 4: Shift nginx site to use the new cert"
echo " "

sed -i "s/develop.json.cpp.al/$website/" /etc/nginx/sites-available/$website
systemctl reload nginx
