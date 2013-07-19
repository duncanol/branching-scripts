#!/bin/bash

#fail fast if any part of this script fails
set -e

# need to have a branch name specified
function usage() {
  echo "Usage: ./archive-branch.sh -b <branch name> -r <TSB_connect repository location> (to archive the specified branch as archived_<branch name>)
  echo "e.g. ./archive-branch.sh -b live -r ~/development/TSB_connect
  echo ""
  echo "Optional argument -f will cause this script not to prompt user for confirmation of archiving the branch"
  echo "Optional argument -n allows you to specify your own archived branch name e.g. -n my_archived_feature will archive the branch using this name"
  exit 1
}


while getopts fb:r:n: opt; do
  case $opt in
    f) forced=true ;;
    b) branchname=$OPTARG ;;
    r) repositorylocation=$OPTARG ;;
    n) archivedbranchname=$OPTARG ;;
    ?) usage ;;
  esac
done

if [[ -z "$archivedbranchname" ]]
then
  archivedbranchname="archived_""$branchname"
fi

if [[ -z "$branchname" || -z "$repositorylocation" ]]
then
  usage
fi


echo "ARCHIVING BRANCH \"$branchname\""
echo "================"
echo ""

# check out the desired branch and ensure it is up-to-date
cd $repositorylocation
git fetch
git checkout $branchname
git merge origin/$branchname
cd -


function do_archiving() {
  echo "Archiving \"$branchname\" branch as \"$archivedbranchname\" for repository \"$repositorylocation\""
  cd $repositorylocation
  #git checkout -b $archivedbranchname
  #git push origin $archivedbranchname
  #git push origin :branchname
  #git branch -d :branchname
  
  cd -
}


if [ $forced ] 
then
  do_archiving
else
  echo ""
  echo "You are about to archive \"$branchname\" branch as \"$archivedbranchname\" in the repository \"$repositorylocation\"."
  read -p "Are you sure you want to continue? (y/n) " -n 1
  echo ""
  echo ""

  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "Cancelled."
    exit 1
  else
    do_archiving
  fi
fi

echo ""
echo ""
echo "Finished archiving branch successfully!"
