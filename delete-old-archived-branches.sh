#!/bin/bash
function usage() {
  echo "Usage: delete-archived-branches.sh -d <number of days old or more> -r <repository location>"
  echo "e.g. ./delete-old-archived-branches.sh -d 100 -r ~/development/TSB_connect (to find branches 100 days or more old, based upon the date of their last commit)"
  exit 1
}


while getopts d:r:f opt; do
  case $opt in
    d) days_old_threshold=$OPTARG ;;
    r) repositorylocation=$OPTARG ;;
    f) forced=true ;;
    ?) usage ;;
  esac
done

if [[ -z "$days_old_threshold" || -z "$repositorylocation" ]]
then
  usage
fi

oldbranches="`./find-old-branches.sh -d $days_old_threshold -r $repositorylocation | grep archived_ | sed 's/\".*\/\(.*\)\".*/\1/'`"



if [[ -z "$oldbranches" ]]
then
  echo "There are no branches to delete.  Goodbye!"
  exit
fi


function do_deleting() {
  
  for branchname in $oldbranches 
  do
    
    echo "Deleting branch $branchname..."
    # git push origin :$branchname
    # git branch -d $branchname 
  done

}

if [ $forced ]
then
  do_deleting
else
  echo ""
  echo "You are about to delete the following branches from the \"$repositorylocation\" repository."
  echo ""
  echo "$oldbranches"
  echo ""
  read -p "Are you sure you want to continue? (y/n) " -n 1
  echo ""
  echo ""

  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "Cancelled."
    exit 1
  else
    do_deleting
  fi
fi
