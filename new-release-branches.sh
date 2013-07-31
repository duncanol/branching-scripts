#!/bin/bash

#fail fast if any part of this script fails
set -e

#print out the commands executed in this script
#set -x


thisdir=`pwd`



# need to have a branch name specified
function usage() {
  echo "Usage: ./new-release-branches.sh -v <new pom version> -n <release name> -r <TSB_connect repository location> -e <TSB_connect-extras location>"
  echo "e.g. ./new-release-branches.sh -v 1.1.0 -n release1.1 -r ~/development/TSB_connect -e ~/development/TSB_connect-extras (to create new UAT-release1.1 and new QA-release1.1 branches at pom version 1.1.0 for both the main and the extras repositories)"
  echo ""
  echo "Optional argument -f will cause this script not to prompt user for confirmation of creating new branches"
  exit 1
}


while getopts fv:n:r:e: opt; do
  case $opt in
    f) forced=true; forcedoption="-f" ;;
    n) branchname=$OPTARG ;;
    v) pomversion=$OPTARG ; snapshotversion="$pomversion-SNAPSHOT" ;;
    r) repositorylocation=$OPTARG ;;
    e) extraslocation=$OPTARG ;;
    ?) usage ;;
  esac
done

if [[ -z "$branchname" || -z "$pomversion" || -z "$repositorylocation" || -z "$extraslocation" ]]
then
  usage
fi


echo "Creating branches for a new Release"
echo "==================================="
echo ""


function checkout-branch() {

  cd $1
  git fetch
  
  if [[ -z "`git branch -al | cut -c3- | sed 's/remotes\/origin\///' | grep -e "^$2$"`" ]]
  then
    echo "Could not find branch \"$2\" in repository \"$1\""
    return 1
  fi

  git checkout $2
  git merge origin/$2
  return 0 
}

function checkout-tag() {
  
  cd $1
  git fetch
  
  if [[ -z "`git tag -l | grep -e "^$2$"`" ]]
  then
    echo "Could not find tag \"$2\" in repository \"$1\""
    return 1
  fi

  git checkout $2
  return 0 
}

function new-branch() {

  # navigate to the target repo and create a new branch based upon the requested branch  
  checkout-branch $1 $2
  git checkout -b $3
  git push origin $3
}


function update-main-repo-pom-versions() {
  cd $repositorylocation
  currentversion=`mvn -pl . help:evaluate -Dexpression=project.version | grep -v "^\["`
  mvn versions:set -DnewVersion=$pomversion
  find . -name '*.versionsBackup' | xargs rm
  git commit -am "Updating POM versions from $currentversion to $pomversion"
  git push origin UAT_$branchname
}


function tag-branch() {
  checkout-branch $1 $2
  git tag $3
  git push --tags 
}








function do-work() {
  new-branch $repositorylocation live UAT_$branchname
  new-branch $extraslocation live UAT_$branchname
  update-main-repo-pom-versions
  tag-branch $repositorylocation UAT_$branchname $pomversion
  tag-branch $extraslocation UAT_$branchname $pomversion
}








if [ $forced ]
then
  do-work
else
  echo ""
  echo "You are about to create new release branches based on live.  This will create a new UAT branch called \"UAT_$branchname\" at pom version \"$pomversion\" and a QA branch called \"QA_$branchname\" at pom version \"$snapshotversion\".  These branches will then be tagged as \"$pomversion\" and \"$snapshotversion\" respectively."
  echo ""
  echo "This will be performed to the repositories located at \"$repositorylocation\" and \"$extraslocation\""
  echo ""
  read -p "Are you sure you want to continue? (y/n) " -n 1
  echo ""
  echo ""

  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "Cancelled."
    exit 1
  else
    do-work
  fi
fi

echo ""
echo ""
echo "Finished creating release branches successfully!"
