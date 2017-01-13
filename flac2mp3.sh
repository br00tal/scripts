#!/bin/sh

SRCDIR=$1
DSTDIR=`find /run/media/${USER} -maxdepth 1 -mindepth 1 -type d | tail -1`

if [ "$DSTDIR" == "" ]; then
  echo "No destination directory found."
  exit 1
fi

if [ ! -d "$SRCDIR" ]; then
  echo "Input needs to be a directory."
  exit 1
fi

DIR=`basename "$SRCDIR"`

cp -rp "$SRCDIR" "$DSTDIR"
find "${DSTDIR}/${DIR}" -type f -name "*.flac" | while read -r i; do
  ffmpeg -i "${i}" -qscale:a 0 "${i[@]/%flac/mp3}" < /dev/null
  rm -rf "$i"
done
