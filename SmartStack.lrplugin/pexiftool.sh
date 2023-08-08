#!/bin/bash
#Good for speed when re-reading existing imported files, but requires sorting 
#when importing for sequence matching to work
lines=$(wc -l $1)
threads=1
if $((lines -gt 100)) ; then
 threads=12
fi
exiftool=/opt/homebrew/bin/exiftool
tmpdir=$(mktemp -d)
trap "rm -rf $tmpdir" 0 2 3 15
inputlist=$1
shift
for i in `seq 0 $((threads-1))`; do
  cat $inputlist | awk "NR % $threads == $i" | $exiftool "$@" -@ - 2>&1 > $tmpdir/out.$i &
done
wait $(jobs -rp)
for i in `seq 0 $((threads-1))`; do
 cat $tmpdir/out.$i
done


