#!/bin/bash

# Create a jenkins job
#
# # Copyright 2024 Sam Darwin
#
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at http://boost.org/LICENSE_1_0.txt)

set -e

scriptname="create-jenkins-job.sh"
scriptlocation=$(pwd)

# set defaults:

# The job will be created in _another_ github organization, not the specified one.
# That is so it can be tested before going live, since testing is almost always necessary.
# After running the script first without the -d flag, and confirming that everything works,
# run it again with -d.

# shellcheck disable=SC2034
github_test_org="sdarwin"

# READ IN COMMAND-LINE OPTIONS

TEMP=$(getopt -o h::,d:: --long help::,deploy:: -- "$@")
eval set -- "$TEMP"

# extract options and their arguments into variables.
while true ; do
    case "$1" in
        -h|--help)
            helpmessage="""
usage: $scriptname [-h] [url_of_library_repo]

Builds library documentation.

optional arguments:
  -h, --help            Show this help message and exit
  -d, --deploy          Convert an initial test job to production
standard arguments:
  url_of_library_repo	Example: https://github.com/acme/example
"""

            echo ""
	    echo "$helpmessage" ;
	    echo ""
            exit 0
            ;;
	-d|--deploy)
	    deployoption="yes" ; shift 2 ;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done

if [ -z "${GH_TOKEN}" ]; then
    # shellcheck source=/dev/null
    . ~/.config/github_credentials
fi

if [ -z "${GH_TOKEN}" ]; then
    echo "Please set the environment variable export GH_TOKEN="
    echo "If included in ~/.config/github_credentials the script will source that file"
    echo "Exiting"
    exit 1
fi

if [ -n "$1" ]; then
    repo_url=$1
    repo_name=$(basename -s .git "${repo_url}")
    # shellcheck disable=SC2034,SC2046
    repo_org=$(basename $(dirname "${repo_url}"))
else
    echo "Repo URL not set. Exiting."
    exit 1
fi

function initial_main_setup {

    echo "Setting up a test version of the job"

    ####################
    #
    # The first series of steps creates a pull request in the github_test_org organization
    # which will be used to test jenkins jobs with pull requests
    #
    ####################

    mkdir -p ~/github/jenkins_scripts
    cd ~/github/jenkins_scripts
    if [ ! -d "${repo_name}" ]; then
        git clone "${repo_url}"
    fi
    
    cd "${repo_name}"
    # shellcheck disable=SC2034
    localrepodir=$(pwd)
    
    if git remote -v | grep upstream ; then
        echo "upstream remote found. The fork has likely already been done. Continuing."
    else
        echo "Running gh repo fork --remote"
        gh repo fork --remote
        gh repo set-default "${github_test_org}/${repo_name}"
    fi
    
    if git remote -v | grep origin | grep ${github_test_org} ; then
        echo "validation step: the git origin repo matches this script's github_test_org. Ok."
    else
        echo "validation step: the git origin repo does not matches this script's github_test_org. Exiting."
        exit 1
    fi
    
    if git branch -avv | grep prtest | grep "testing pull request" ; then
        echo "The prtest branch already exists. Switching to that."
        echo "git checkout prtest"
        git checkout prtest
    else
        echo "git checkout -b prtest"
        git checkout -b prtest
    fi
    
    if gh pr list | grep prtest | grep "testing pull request" ; then
        echo "Test PR already exists. Continuing."
    else
        echo "Generating a test PR."
        echo " " >> README.md || true
        echo " " >> README.adoc || true
        
        git config user.name testbot
        git config user.email testbot@example.com
        
        git remote set-url origin "https://testbot:${GH_TOKEN}@github.com/${github_test_org}/${repo_name}"
        
        git add .
        git commit -m "testing pull request doc previews"
        git push --set-upstream origin prtest
        
        # For security, let's put the URL back to normal
        git remote set-url origin "https://github.com/${github_test_org}/${repo_name}"
        
        gh pr create --base develop -R "${github_test_org}/${repo_name}" --title "testing pull request doc previews" --body "Don't merge this PR"
    fi
    
    #####################
    #
    # Determine the type of repo
    #
    #####################
    
    if [ -f doc/build_antora.sh ] ; then
        jobtype="antora_libraries_1"
    else
        jobtype="standard_libraries_1"
    fi
    
    tmpdir=$(mktemp -d)
    
    cp "$scriptlocation/job-templates/${jobtype}/config.xml" "${tmpdir}/config.xml"
    cd "${tmpdir}"
    
    echo "Running sed to customize config.xml in ${tmpdir}"
    sed -i "s/template_repository/${repo_name}/g" config.xml
    sed -i "s/template_organization/${github_test_org}/g" config.xml
    # Still in testing mode for a new repo:
    echo "second to last"
    sed -i "s|cppalliance/jenkins-ci|${github_test_org}/jenkins-ci|" config.xml
    echo "last sed"
    sed -i "s|<name>\*/master</name>|<name>\*/testing</name>|" config.xml
    
    mkdir -p "/var/lib/jenkins/jobs/${repo_name}"
    chown jenkins:jenkins "/var/lib/jenkins/jobs/${repo_name}"
    chown jenkins:jenkins config.xml
    destfile="/var/lib/jenkins/jobs/${repo_name}/config.xml"
    if [ ! -f "${destfile}" ]; then
        cp -p config.xml "/var/lib/jenkins/jobs/${repo_name}/config.xml"
        # shellcheck source=/dev/null
        . ~/.config/jenkins_credentials
        java -jar /usr/bin/jenkins-cli.jar -s http://localhost:8080 -auth "$JENKINS_USER:$JENKINS_PASSWORD" reload-configuration
    else
        echo "The job, and config.xml, already exist, at ${destfile}. Not copying in a new file."
    fi
}

function deploy_job {
 
    echo "Deploy the test job to production"

    configfile="/var/lib/jenkins/jobs/${repo_name}/config.xml"
    sed -i "s|$github_test_org|$repo_org|g" "${configfile}"
    sed -i "s|<name>\*/testing</name>|<name>\*/master</name>|" "${configfile}"
    # shellcheck source=/dev/null
    . ~/.config/jenkins_credentials
    java -jar /usr/bin/jenkins-cli.jar -s http://localhost:8080 -auth "$JENKINS_USER:$JENKINS_PASSWORD" reload-configuration
}

if [ "$deployoption" == "yes" ]; then
    # After the job has been tested:
    deploy_job
else
    # The most common first step:
    initial_main_setup
fi

