#!/bin/bash
function usage() {
  echo "Usage: find-old-archived-branches.sh -d <number of days old or more> -r <repository location>"
  echo "e.g. ./find-old-archived-branches.sh -d 100 -r ~/development/TSB_connect (to find branches 100 days or more old, based upon the date of their last commit)"
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

./find-old-branches.sh -d $days_old_threshold -r $repositorylocation | grep archived_
