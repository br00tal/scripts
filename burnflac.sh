#!/bin/sh

BURNDIR=/tmp/burn
CDRECORDGLOB="dev=/dev/sr0 speed=48"
CDRECORDOPTS="-dao -eject -pad -audio"

rm -rf $BURNDIR/* > /dev/null
mkdir -p $BURNDIR
echo -n "Enter the path containing the .flac files: "
read -e LOC

cp "$LOC"/*.flac $BURNDIR/
cd $BURNDIR
flac -d *.flac

sudo cdrecord $CDRECORDGLOB $CDRECORDOPTS *.wav

rm -rf $BURNDIR/*
