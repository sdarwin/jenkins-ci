## Jenkins Job Details 
  
For a summary of how Jenkins works, please refer back to [this page](jenkins-summary.md).  
  
Here, we will go into exhaustive detail about every job, as a reference document.  
  
### General Server Setup
  
Install Jenkins - https://www.jenkins.io/doc/book/installing/  
  
Install SSL certificates:  
```  
apt install certbot  
certbot certonly  
```  
  
Install nginx.  
Create website:  
```  
server {  
    listen 80;  
    listen [::]:80;  
    server_name jenkins.cppalliance.org;  
    location '/.well-known/acme-challenge' {  
        default_type "text/plain";  
        root /var/www/letsencrypt;  
    }  
    location / {  
         return 301 https://jenkins.cppalliance.org:8443$request_uri;  
    }  
}  
  
server {  
listen 8443 ssl default_server;  
listen [::]:8443 ssl default_server;  
ssl_certificate /etc/letsencrypt/live/jenkins.cppalliance.org/fullchain.pem;  
ssl_certificate_key /etc/letsencrypt/live/jenkins.cppalliance.org/privkey.pem;  
#include snippets/snakeoil.conf;  
location / {  
include /etc/nginx/proxy_params;  
proxy_pass http://localhost:8080;  
proxy_read_timeout 90s;  
}  
}  
```  
  
Install the plugin "GitHub pull requests builder"  
Go to ``Manage Jenkins`` -> ``Configure System`` -> ``GitHub pull requests builder`` section.  
  
"Create API Token"  
  
Update "Commit Status Build Triggered", "Commit Status Build Start" to --none--  
Create all three types of "Commit Status Build Result" with --none--  
  
On the server:  
  
```  
apt install git build-essential  
#given that the build was moved into a docker container, these may not still be required:  
apt install ruby  
apt install ruby-dev   
gem install bundler  
```  
  
Install the plugin "CloudBees Docker Custom Build Environment"  
  
docker pull circleci/ruby:2.4-node-browsers-legacy  
  
add Jenkins to docker group. Restart jenkins.  
  
Install CloudBees AWS Credentials, and add credentials (although I believe this was superceded by the S3 plugin, and not required.)  
  
Install S3 publisher plugin  
  
In Manage Jenkins->Configure System, go to S3 Profiles, create profile cppalliance-bot-profile with the AWS creds.  
  
Install Post Build Task plugin 
 
### Pre-install requirements for building Boost docs 
  
```  
apt-get update  
apt-get install -y docbook docbook-xml docbook-xsl xsltproc libsaxonhe-java   
apt-get install cmake flex bison  
apt-get install build-essential python  
  
cd /opt/github  
git clone -b 'Release_1_8_15' --depth 1 https://github.com/doxygen/doxygen.git  
cd doxygen  
cmake -H. -Bbuild -DCMAKE_BUILD_TYPE=Release  
cd build  
sudo make install  
  
mkdir /opt/github/saxonhe  
cd /opt/github/saxonhe  
wget -O saxonhe.zip https://sourceforge.net/projects/saxon/files/Saxon-HE/9.9/SaxonHE9-9-1-4J.zip/download  
unzip saxonhe.zip  
sudo rm /usr/share/java/Saxon-HE.jar  
sudo cp saxon9he.jar /usr/share/java/Saxon-HE.jar  
```  
  
### Nginx Setup
  
Create a wildcard dns:  
*.prtest.cppalliance.cppalliance.org CNAME to jenkins.cppalliance.org  
  
Create an nginx site for previews:  
  
```  
server {  
    # Listen on port 80 for all IPs associated with your machine  
    listen 80 default_server;  
  
    # Catch all other server names  
    server_name _;  
  
    if ($host ~* ([0-9]+)\.(.*?)\.(.*)) {  
        set $pullrequest $1;  
        set $repo $2;  
    }  
  
    location / {  
        # This code rewrites the original request  
        # E.g. if someone requests  
        # /directory/file.ext?param=value  
        # from the coolsite.com site the request is rewritten to  
        # /coolsite.com/directory/file.ext?param=value  
        set $backendserver 'http://cppalliance-previews.s3-website-us-east-1.amazonaws.com';  
        # echo "$backendserver";  
  
        #CUSTOMIZATIONS  
        #news customization  
        if ($repo = "cppalliance" ) {  
          rewrite ^(.*)/news$ $1/news.html ;  
	  rewrite ^(.*)/people/([a-zA-Z0-9]+)$ $1/people/$2.html ;
        }  
  
        #FINAL REWRITE  
        rewrite ^(.*)$ $backendserver/$repo/$pullrequest$1 break;  
  
  
        # The rewritten request is passed to S3  
        proxy_pass http://cppalliance-previews.s3-website-us-east-1.amazonaws.com;  
        #proxy_pass $backendserver;  
        include /etc/nginx/proxy_params;  
        proxy_redirect /$repo/$pullrequest / ;  
    }  
}  
  
```  
  
### AWS Setup  
  
Turn on static web hosting on the bucket.  
Endpoint is http://cppalliance-previews.s3-website-us-east-1.amazonaws.com  
  
Add bucket policy  
  
```  
{  
    "Version": "2012-10-17",  
    "Statement": [  
        {  
            "Sid": "PublicReadGetObject",  
            "Effect": "Allow",  
            "Principal": "*",  
            "Action": "s3:GetObject",  
            "Resource": "arn:aws:s3:::cppalliance-previews/*"  
        }  
    ]  
}  
```  
  
Add permissions in IAM for cppalliance-bot  
  
```  
    "Version": "2012-10-17",  
    "Statement": [  
        {  
            "Effect": "Allow",  
            "Action": [  
                "s3:GetBucketLocation",  
                "s3:ListAllMyBuckets"  
            ],  
            "Resource": "*"  
        },  
        {  
            "Effect": "Allow",  
            "Action": [  
                "s3:ListBucket"  
            ],  
            "Resource": [  
                "arn:aws:s3:::cppalliance-previews"  
            ]  
        },  
        {  
            "Effect": "Allow",  
            "Action": [  
                "s3:PutObject",  
                "s3:GetObject",  
                "s3:DeleteObject"  
            ],  
            "Resource": [  
                "arn:aws:s3:::cppalliance-previews/*"  
            ]  
        }  
    ]  
}  
```  
  
### JENKINS FREESTYLE PROJECTS   
---  
  
### NuDB   
  
Github Project (checked)  
Project URL: https://github.com/cppalliance/NuDB/  
  
Source Code Management  
Git (checked)  
Repositories: https://github.com/cppalliance/NuDB  
Credentials: github-cppalliance-bot  
Advanced:  
Refspec: +refs/pull/*:refs/remotes/origin/pr/*  
Branch Specifier: ${ghprbActualCommit}  
  
Build Triggers  
GitHub Pull Request Builder (checked)  
GitHub API Credentials: cppbot  
  
Advanced:  
Build every pull request automatically without asking (Dangerous!). (checked)  
  
Trigger Setup:    
Build Status Message:    
`An automated preview of the documentation is available at [http://$ghprbPullId.nudbdocs.prtest.cppalliance.org/libs/nudb/doc/html/index.html](http://$ghprbPullId.nudbdocs.prtest.cppalliance.org/libs/nudb/doc/html/index.html) `    
Update Commit Message during build:  
Commit Status Build Triggered: --none--  
Commit Status Build Started: --none--  
Commit Status Build Result: create all types of result, with message --none--  
  
Build:  
Execute Shell:  
```  
#!/bin/bash  
echo "Starting check to see if docs have been updated."  
counter=0  
for i in $(git diff --name-only HEAD HEAD~1)  
do  
  if [[ $i =~ ^doc/ ]]; then  
    counter=$((counter+1))  
  fi  
done  
  
if [ "$counter" -eq "0" ]; then  
  echo "No docs found. Exiting."  
  exit 1  
else  
  echo "Found $counter docs. Proceeding."  
fi  
  
  
if [ ! -d boost-root ]; then  
  git clone -b master https://github.com/boostorg/boost.git boost-root  
fi  
  
#nudb 2020-05  
git submodule update --init doc/docca  
cd doc  
chmod 755 makeqbk.sh  
./makeqbk.sh  
cd ..  
sed -i 's,path-constant TEST_MAIN : $(BOOST_ROOT)/boost/beast/_experimental/unit_test/main.cpp ;,,' Jamroot  
#  
  
cd boost-root  
git pull  
export BOOST_ROOT=$(pwd)  
git submodule update --init libs/context  
git submodule update --init tools/boostbook  
git submodule update --init tools/boostdep  
git submodule update --init tools/docca  
git submodule update --init tools/quickbook  
  
rsync -av --exclude boost-root ../ libs/nudb  
python tools/boostdep/depinst/depinst.py ../tools/quickbook  
./bootstrap.sh  
./b2 headers  
  
echo "using doxygen ; using boostbook ; using saxonhe ;" > tools/build/src/user-config.jam  
  
./b2 -j3 libs/nudb/doc//boostdoc   
```  
  
Post-build Actions  
Publish artifacts to S3  
S3 Profile: cppalliance-bot-profile  
  
Source: boost-root/doc/**  
Destination:  cppalliance-previews/nudbdocs/${ghprbPullId}/doc  
Bucket Region: us-east-1  
No upload on build failure (checked)  
  
Source: boost-root/libs/nudb/doc/**  
Destination:  cppalliance-previews/nudbdocs/${ghprbPullId}/libs/nudb/doc  
Bucket Region: us-east-1  
No upload on build failure (checked)  
  
Source: boost-root/index.html  
Destination:  cppalliance-previews/nudbdocs/${ghprbPullId}  
Bucket Region: us-east-1  
No upload on build failure (checked)  
  
Source: boost-root/more/**  
Destination:  cppalliance-previews/nudbdocs/${ghprbPullId}/more  
Bucket Region: us-east-1  
No upload on build failure (checked)  
  
Source: boost-root/boost.png  
Destination:  cppalliance-previews/nudbdocs/${ghprbPullId}  
Bucket Region: us-east-1  
No upload on build failure (checked)  
  
-------------------------------------------------------------------------------------------------------------------------  
  
### JSON   
  
Github Project (checked)  
Project URL: https://github.com/cppalliance/json  
  
Source Code Management  
Git (checked)  
Repositories: https://github.com/cppalliance/json  
Credentials: github-cppalliance-bot  
Advanced:  
Refspec: +refs/pull/*:refs/remotes/origin/pr/*  
Branch Specifier: ${ghprbActualCommit}  
  
Build Triggers  
GitHub Pull Request Builder (checked)  
GitHub API Credentials: cppbot  
  
Advanced:  
Build every pull request automatically without asking (Dangerous!). (checked)  
  
Trigger Setup:    
Build Status Message:    
`An automated preview of the documentation is available at [http://$ghprbPullId.jsondocs.prtest.cppalliance.org/libs/json/doc/html/index.html](http://$ghprbPullId.jsondocs.prtest.cppalliance.org/libs/json/doc/html/index.html)`  
Update Commit Message during build:  
Commit Status Build Triggered: --none--  
Commit Status Build Started: --none--  
Commit Status Build Result: create all types of result, with message --none--  
  
Build:  
Execute Shell:  
```  
#!/bin/bash  
echo "Starting check to see if docs have been updated."  
counter=0  
for i in $(git diff --name-only HEAD HEAD~1)  
do  
  if [[ $i =~ ^doc/ ]]; then  
    counter=$((counter+1))  
  fi  
done  
  
if [ "$counter" -eq "0" ]; then  
  echo "No docs found. Exiting."  
  exit 1  
else  
  echo "Found $counter docs. Proceeding."  
fi  
  
if [ ! -d boost-root ]; then  
  git clone -b master https://github.com/boostorg/boost.git boost-root  
fi  
cd boost-root  
export BOOST_ROOT=$(pwd)  
git pull  
git submodule update --init libs/context  
git submodule update --init tools/boostbook  
git submodule update --init tools/boostdep  
git submodule update --init tools/docca  
git submodule update --init tools/quickbook  
rsync -av --exclude boost-root ../ libs/json  
python tools/boostdep/depinst/depinst.py ../tools/quickbook  
./bootstrap.sh  
./b2 headers  
  
echo "using doxygen ; using boostbook ; using saxonhe ;" > tools/build/src/user-config.jam  
./b2 -j3 libs/json/doc//boostrelease  
 ```  
  
Post-build Actions  
Publish artifacts to S3  
S3 Profile: cppalliance-bot-profile  
  
Source: boost-root/doc/**  
Destination:  cppalliance-previews/jsondocs/${ghprbPullId}/doc  
Bucket Region: us-east-1  
No upload on build failure (checked)  
  
Source: boost-root/libs/json/doc/**  
Destination:  cppalliance-previews/jsondocs/${ghprbPullId}/libs/json/doc  
Bucket Region: us-east-1  
No upload on build failure (checked)  
  
Source: boost-root/index.html  
Destination:  cppalliance-previews/jsondocs/${ghprbPullId}  
Bucket Region: us-east-1  
No upload on build failure (checked)  
  
Source: boost-root/more/**  
Destination:  cppalliance-previews/jsondocs/${ghprbPullId}/more  
Bucket Region: us-east-1  
No upload on build failure (checked)  
  
Source: boost-root/boost.png  
Destination:  cppalliance-previews/jsondocs/${ghprbPullId}  
Bucket Region: us-east-1  
No upload on build failure (checked)  
  
--------------------------------------------------------------------------------------------------------------  
  
### Beast   
  
Github Project (checked)  
Project URL: https://github.com/boostorg/beast/  
  
Source Code Management  
Git (checked)  
Repositories: https://github.com/boostorg/beast  
Credentials: github-cppalliance-bot  
Advanced:  
Refspec: +refs/pull/*:refs/remotes/origin/pr/*  
Branch Specifier: ${ghprbActualCommit}  
  
Build Triggers  
GitHub Pull Request Builder (checked)  
GitHub API Credentials: cppbot  
  
Advanced:  
Build every pull request automatically without asking (Dangerous!). (checked)  
  
Trigger Setup:    
Build Status Message:    
`An automated preview of the documentation is available at [http://$ghprbPullId.beastdocs.prtest.cppalliance.org/libs/beast/doc/html/index.html](http://$ghprbPullId.beastdocs.prtest.cppalliance.org/libs/beast/doc/html/index.html)`  
Update Commit Message during build:  
Commit Status Build Triggered: --none--  
Commit Status Build Started: --none--  
Commit Status Build Result: create all types of result, with message --none--  
  
Build:  
Execute Shell:  
```  
#!/bin/bash  
echo "Starting check to see if docs have been updated."  
counter=0  
for i in $(git diff --name-only HEAD HEAD~1)  
do  
  if [[ $i =~ ^doc/ ]]; then  
    counter=$((counter+1))  
  fi  
done  
  
if [ "$counter" -eq "0" ]; then  
  echo "No docs found. Exiting."  
  exit 1  
else  
  echo "Found $counter docs. Proceeding."  
fi  
  
if [ ! -d boost-root ]; then  
  git clone -b master https://github.com/boostorg/boost.git boost-root  
fi  
cd boost-root  
git pull  
git submodule update --init libs/context  
git submodule update --init tools/boostbook  
git submodule update --init tools/boostdep  
git submodule update --init tools/docca  
git submodule update --init tools/quickbook  
rsync -av --exclude boost-root ../ libs/beast  
python tools/boostdep/depinst/depinst.py ../tools/quickbook  
./bootstrap.sh  
./b2 headers  
  
echo "using doxygen ; using boostbook ; using saxonhe ;" > tools/build/src/user-config.jam  
./b2 -j3 libs/beast/doc//boostrelease  
```  
  
Post-build Actions  
Publish artifacts to S3  
S3 Profile: cppalliance-bot-profile  
  
Source: boost-root/doc/**  
Destination:  cppalliance-previews/beastdocs/${ghprbPullId}/doc  
Bucket Region: us-east-1  
No upload on build failure (checked)  
  
Source: boost-root/libs/beast/doc/**  
Destination:  cppalliance-previews/beastdocs/${ghprbPullId}/libs/beast/doc  
Bucket Region: us-east-1  
No upload on build failure (checked)  
  
Source: boost-root/index.html  
Destination:  cppalliance-previews/beastdocs/${ghprbPullId}  
Bucket Region: us-east-1  
No upload on build failure (checked)  
  
Source: boost-root/more/**  
Destination:  cppalliance-previews/beastdocs/${ghprbPullId}/more  
Bucket Region: us-east-1  
No upload on build failure (checked)  
  
Source: boost-root/boost.png  
Destination:  cppalliance-previews/beastdocs/${ghprbPullId}  
Bucket Region: us-east-1  
No upload on build failure (checked)  
  
-------------------------------------------------------------------------------------------------------------------------  
  
### vinniefalco.github.io   
  
Github Project (checked)  
Project URL: https://github.com/vinniefalco/vinniefalco.github.io/  
  
Source Code Management  
Git (checked)  
Repositories: https://github.com/vinniefalco/vinniefalco.github.io  
Credentials: github-cppalliance-bot  
Advanced:  
Refspec: +refs/pull/*:refs/remotes/origin/pr/*  
Branch Specifier: ${ghprbActualCommit}  
  
Build Triggers  
GitHub Pull Request Builder (checked)  
GitHub API Credentials: cppbot  
  
Advanced:  
Build every pull request automatically without asking (Dangerous!). (checked)  
  
Trigger Setup:    
Build Status Message:    
`An automated preview of this PR is available at [http://$ghprbPullId.vinniefalco.prtest.cppalliance.org](http://$ghprbPullId.vinniefalco.prtest.cppalliance.org)`  
Update Commit Message during build:  
Commit Status Build Triggered: --none--  
Commit Status Build Started: --none--  
Commit Status Build Result: create all types of result, with message --none--  
  
Build:  
Execute Shell:  
```  
#!/bin/bash  
  
#no actions here, for now  
true   
```  
  
Post-build Actions  
Publish artifacts to S3  
S3 Profile: cppalliance-bot-profile  
  
Source: **  
Destination:  cppalliance-previews/vinniefalco/${ghprbPullId}  
Bucket Region: us-east-1  
No upload on build failure (checked)  
  
-------------------------------------------------------------------------------------------------------------------------  
  
### cppalliance website   
  
Github Project (checked)  
Project URL: https://github.com/CPPAlliance/cppalliance.github.io/  
  
Source Code Management  
Git (checked)  
Repositories: https://github.com/CPPAlliance/cppalliance.github.io  
Credentials: github-cppalliance-bot  
Advanced:  
Refspec: +refs/pull/*:refs/remotes/origin/pr/*  
Branch Specifier: ${ghprbActualCommit}  
  
Build Triggers  
GitHub Pull Request Builder (checked)  
GitHub API Credentials: cppbot  
  
Advanced:  
Build every pull request automatically without asking (Dangerous!). (checked)  
  
Trigger Setup:    
Build Status Message:    
`An automated preview of this PR is available at [http://$ghprbPullId.cppalliance.prtest.cppalliance.org](http://$ghprbPullId.cppalliance.prtest.cppalliance.org)`  
Update Commit Message during build:  
Commit Status Build Triggered: --none--  
Commit Status Build Started: --none--  
Commit Status Build Result: create all types of result, with message --none--  
  
Build Environment:  
Build inside a Docker container (checked)  
Pull docker image from repository: circleci/ruby:2.4-node-browsers-legacy  
  
Build:  
Execute Shell:  
```  
export HOME=$(pwd)  
bundle install  
bundle exec jekyll build  
```  
  
Post-build Actions  
Publish artifacts to S3  
S3 Profile: cppalliance-bot-profile  
  
Source: _site/**  
Destination:  cppalliance-previews/cppalliance/${ghprbPullId}  
Bucket Region: us-east-1  
No upload on build failure (checked)  

Add Post Build Tasks

Log Text: GitHub

Script:

```
#!/bin/bash
PREVIEWMESSAGE="A preview of the cppalliance website is available at http://$ghprbPullId.cppalliance.prtest.cppalliance.org"
curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"$PREVIEWMESSAGE\"}"  https://hooks.slack.com/services/T21Q22G66/B0141JDEYMT/aPF___
```

Check box "Run script only if all previous steps were successful"

In Slack administration, (not in jenkins), create a Slack app. Create a webhook for the cppalliance channel. That webhook goes into the curl command.

