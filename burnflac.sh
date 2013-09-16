#!/bin/sh

DEVS=`cat /proc/sys/dev/cdrom/info | grep "drive name" | awk '{$1=$2=""; print $0}' | sed -e 's/^[ \t]*//'`
DEVCOUNT=`echo $DEVS | wc -w`
DEVTYPES=`cat /proc/sys/dev/cdrom/info | grep "Can write CD-R:"`
BURNDIR=/tmp/burn
DEVICE=
SPEED=48

if [ "X$DEVICE" == "X" ]; then
  if [ "$DEVCOUNT" == "0" ]; then
    echo "No drives found.  Exiting..."
    exit 1
  else
    for (( i=1; i<=$DEVCOUNT; i++ )); do
      POSITION=3
      POSITION=$((POSITION + $i))
      BURNER=`echo $DEVTYPES | awk -v POS=$POSITION '{print $POS}'`
      if [ "$BURNER" == "1" ]; then
        DEVICE=`echo $DEVS | awk -v C=$i '{print "/dev/" $C}'`
        echo "No device specified.  Using auto-detected device $DEVICE."
      else
        echo "No device found or specified.  Exiting..."
        exit 1
      fi
    done
  fi
fi

CDRECORDGLOB="dev=$DEVICE speed=$SPEED"
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
