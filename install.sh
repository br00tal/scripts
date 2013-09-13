#!/bin/sh

INSTDIR="/usr/local/bin"
FILE="$1"
USER=`id -u`

if [ "$USER" != "0" ]; then
  echo "This needs to be executed as root."
  exit 1
fi

if [ "X$FILE" == "X" ]; then
  echo "No file specified.  Please specify file to install."
  exit 1
fi

cp $FILE $INSTDIR/
chown root:root $INSTDIR/$FILE

