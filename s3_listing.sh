#!/bin/bash
# Based on https://github.com/kaihendry/s3listing/blob/master/listing.sh

s3ns=http://s3.amazonaws.com/doc/2006-03-01/
tmp=$(mktemp -d)

while [ -n "$1" ]
do
  s3url=$1 && shift

  test "$s3url" || continue
  i=0

  # Normalise URL
  s3url=$(curl $s3url -s -L -I -o /dev/null -w '%{url_effective}')

  if [ "${s3url:(-1)}" != "/" ]
  then
    s3url=${s3url}/
  fi

  # s3get gets marker requests appended to it
  s3get=$s3url

  while :; do
    curl -f -s $s3get > "$tmp/$i.xml"
    if test $? -ne 0
    then
      echo ERROR $? retrieving: $s3get 1>&2
      break
    fi
    xmlstarlet sel -N x="$s3ns" -T -t -m "/x:ListBucketResult/x:Contents" -v "concat(x:LastModified,' ',x:Size,' ',x:Key)" -n $tmp/$i.xml
    nextkey=$(xmlstarlet sel -T -N "w=$s3ns" -t \
      --if '/w:ListBucketResult/w:IsTruncated="true"' \
      -v 'str:encode-uri(/w:ListBucketResult/w:Contents[last()]/w:Key, true())' \
      -b -n "$tmp/$i.xml")
      # -b -n adds a newline to the result unconditionally,
      # this avoids the "no XPaths matched" message; $() drops newlines.

    rm -f "$tmp/$i.xml"

    if [ -n "$nextkey" ] ; then
      s3get=$(echo $s3get | sed "s/[?].*//")"?marker=$nextkey"
      i=$((i+1))
    else
      break
    fi
  done
done
