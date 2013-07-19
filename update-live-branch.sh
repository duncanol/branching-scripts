#!/bin/bash

#fail fast if any part of this script fails
set -e

#print out the commands executed in this script
#set -x


thisdir=`pwd`



# need to have a branch name specified
function usage() {
  echo "Usage: ./update-live-branch.sh -t <tag name> -r <TSB_connect repository location> -e <TSB_connect-extras location> -n <release note location>"
  echo "e.g. ./update-live-branch.sh -t 24.0.84 -r ~/development/TSB_connect -e ~/development/TSB_connect-extras -n ~/Documents/release_1.2.doc (to base the new \"live\" branch on the 24.0.84 tag in the repositories, and adding the specified release note to the live branch and committing)"
  echo ""
  echo "Optional argument -f will cause this script not to prompt user for confirmation of updating the live branch"
  exit 1
}


while getopts ft:r:e:n: opt; do
  case $opt in
    f) forced=true ; forcedoption="-f" ;; 
    t) branchname=$OPTARG ;;
    r) repositorylocation=$OPTARG ;;
    e) extraslocation=$OPTARG ;;
    n) releasenotelocation=$OPTARG ;;
    ?) usage ;;
  esac
done

if [[ -z "$branchname" || -z "$repositorylocation" || -z "$extraslocation" || -z "$releasenotelocation" ]]
then
  usage
fi


echo "UPDATING LIVE BRANCH BASED UPON \"$branchname\""
echo "==============================="
echo ""

function do_copying() {

  echo "Finding pom version of \"live\" branch..."
  cd $repositorylocation
  git fetch
  git checkout live
  git merge origin/live
  # find out the pom version
  version=`cat pom.xml | grep '<version>' | head -n1 | sed 's/\(<version>\)\(.*\)\(<\/version>\)/\2/' | xargs echo`
  #version=`mvn -pl . help:evaluate -Dexpression=project.version | grep -v "^\["`

  if [[ -z "$version" ]]
  then
    echo "Could not determine a version number for the \"live\" branch"
    exit 1
  fi

  echo "Archiving old \"live\" branches..."
  archivedbranchname="archived_live_""$version"
  cd $thisdir 
  ./archive-branch.sh -b live -r $repositorylocation -n $archivedbranchname $forcedoption
  ./archive-branch.sh -b live -r $extraslocation -n $archivedbranchname $forcedoption

  echo "Creating latest \"live\" branch based upon tag \"$branchname\"..."

  # check out the desired branch and ensure it is up-to-date
  echo "Checking out tag \"$branchname\" of the repository \"$repositorylocation\""
  cd $repositorylocation
  git fetch

  if [[ -z "`git tag -l | grep -e "^$branchname$"`" ]]
  then
    echo "Could not find tag \"$branchname\" in repository \"$repositorylocation\""
    exit 1
  fi


  git checkout $branchname

  echo "Checking out tag \"$branchname\" of the repository \"$extraslocation\""
  cd $extraslocation
  git fetch
  if [[ -z "`git tag -l | grep -e "^$branchname$"`" ]]
  then
    echo "Could not find tag \"$branchname\" in repository \"$extraslocation\""
    exit 1
  fi
  git checkout $branchname


  cd $repositorylocation


  echo "Creating new \"live\" branch for repository \"$repositorylocation\""
  git checkout -b live
  git push origin live

  echo "Copying Release Note from \"$releasenotelocation\" to \"$repositorylocation\""
  cp "$releasenotelocation" $repositorylocation


  echo "Committing Release Note"
  git add *
  git commit -am 'Added release note to new Live branch'
  git push origin live

echo "Creating new \"live\" branch for repository \"$extraslocation\""
  cd $extraslocation
  git checkout -b live
  git push origin live
}

if [ $forced ] 
then
  do_copying
else
  echo ""
  echo "You are about to archive the current live branch and replace it with the contents of  \"$branchname\" tag as \"live\"."
  echo "The Release Note found at \"$releasenotelocation\" will be committed to the new Live branch"
  read -p "Are you sure you want to continue? (y/n) " -n 1
  echo ""
  echo ""

  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "Cancelled."
    exit 1
  else
    do_copying
  fi
fi

echo ""
echo ""
echo "Finished updating the live branch successfully!"
