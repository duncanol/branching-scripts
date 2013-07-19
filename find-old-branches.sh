#!/bin/bash

function usage() {
  echo ""
  echo "Usage: find-old-branches.sh -d <number of days old or more> -r <repository location>"
  echo "e.g. ./find-old-branches.sh -d 100 -r ~/development/TSB_connect (to find branches 100 days or more old, based upon the date of their last commit)"
  exit 1
}


while getopts d:r: opt; do
  case $opt in
    d) days_old_threshold=$OPTARG ;;
    r) repositorylocation=$OPTARG ;; 
    ?) usage ;;
  esac
done

if [[ -z "$days_old_threshold" || -z "$repositorylocation" ]]
then
  usage
fi

echo "Finding branches more than $days_old_threshold days old"
     
let seconds_old_threshold=60*60*24*$days_old_threshold

cd $repositorylocation
git fetch
old_branches="`git for-each-ref refs/remotes/origin/* --format='%(refname:short)'`"
now_timestamp="`date +%s`"

for branch_name in $old_branches
do

  branch_age_in_days="`git --no-pager show --summary --format=%cr $branch_name | head -n1`"
  branch_age_timestamp="`git --no-pager show --summary --format=%ct $branch_name | head -n1`"

  let age_difference=$now_timestamp-$branch_age_timestamp

  if [ $age_difference -gt $seconds_old_threshold ]
  then
    echo "\"$branch_name\" is more than $days_old_threshold days old	($branch_age_in_days)"
  fi

done
