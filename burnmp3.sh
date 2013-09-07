#!/bin/sh

BURNDIR=/tmp/burn
#CDRECORDGLOB="dev=ATAPI:0,0,0 speed=48"
CDRECORDGLOB="dev=/dev/sr0 speed=48"
CDRECORDOPTS="-dao -eject -pad -audio"

rm -rf $BURNDIR/* > /dev/null
mkdir -p $BURNDIR
echo -n "Enter the path containing the .mp3 files: "
read -e LOC

cp "$LOC"/*.mp3 $BURNDIR/
cd $BURNDIR
IFS=$(echo)
for i in *.mp3; do
	CDR=`basename "$i" .mp3`
	mpg123 -w $CDR.wav $i
done

unset IFS

sudo cdrecord $CDRECORDGLOB $CDRECORDOPTS *.wav

rm -rf $BURNDIR/*
