#!/bin/bash

if [ "$1" == "-d" ]
then
  shift
  dryrun=/usr/bin/true
else
  dryrun=/usr/bin/false
fi

src=$(echo $1 | sed 's:/*$::')
dst=$(echo $2 | sed 's:/*$::')
listing=$(dirname $0)/s3_listing.sh

usage() {
  echo "error: $1"
  echo ""
  echo "usage: $0 <src> <dst>"
  echo "  Where src = an amazon S3 bucket (https://s3.amazonaws.com/mybucket)"
  echo "  and dst is a location in the local filesystem."
}

if ! [ -x "$listing" ]
then
  echo "cannot run $listing"
  exit 1
fi

if [ -z "$src" ]
then
  usage "source bucket not specified"
fi

if [ -z "$dst" ]
then
  usage "destination folder not specified"
fi

bucket_path_component="$(echo $src | sed 's:^.*//::')"

mkdir -p $dst
$listing "$src" | while read line
#cat /tmp/listing.txt | while read line
do
  set $line
  ts="$1"
  #ts=$(echo $line | awk -F ' ' '{print $1}')
  shift
  size="$1"
  #size=$(echo $line | awk -F ' ' '{print $2}')

  #local="$dst/$bucket_path_component/$*"
  key=$(echo "$line" | sed 's/^[^ ]* [^ ]* //')
  local="$dst/$bucket_path_component/$key"
  #remote="$(echo $src/$* | sed -e 's/+/%2b/g')"
  remote=$(echo "$src/$key" | sed -e 's/+/%2b/g')
  
  if [ -e "$local" ]
  then
    local_size=$(stat -f "%z" "$local")
    if [ $size -ne $local_size ] && [ $size -gt 0 ]
    then
      if ! $dryrun
      then
        rm "$local"
        wget -x -P "$dst" "$remote" || true
      else
        echo $size
      fi
    fi
  else
    if [ $size -gt 0 ]
    then
      if ! $dryrun
      then
        wget -x -P "$dst" "$remote" || true
      else
        echo $size
      fi
    fi
  fi
done
