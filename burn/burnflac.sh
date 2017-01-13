#!/bin/sh
#
# burnflac.sh - a script to decode and write .flac files to CD-R(W)s.
#
# Written by br00tal.
#

# Temporary directory to hold generated .wav files for burning.
BURNDIR=/tmp/burn
# CD-ROM device.  Leave blank if you want to try to auto-detect.
DEVICE=
# The burning speed.  Default is 48.
SPEED=48

# Logic if we are to attempt CD-ROM auto-detection.
if [ "X$DEVICE" == "X" ]; then
  DEVS=`cat /proc/sys/dev/cdrom/info | grep "drive name" | awk '{$1=$2=""; print $0}' | sed -e 's/^[ \t]*//'`
  DEVCOUNT=`echo $DEVS | wc -w`
  DEVTYPES=`cat /proc/sys/dev/cdrom/info | grep "Can write CD-R:"`
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

# cdrecord options.
CDRECORDGLOB="dev=$DEVICE speed=$SPEED"
CDRECORDOPTS="-dao -eject -pad -audio"

# Remove anything lingering in $BURNDIR, create it if necessary, and get files.
rm -rf $BURNDIR/* > /dev/null
mkdir -p $BURNDIR
echo -n "Enter the path containing the .flac files: "
read -e LOC

# Copy files to $BURNDIR and decode to .wav files.
cp "$LOC"/*.flac $BURNDIR/
cd $BURNDIR
flac -d *.flac

# Finally, write the .wav files to the CD-R(W).
sudo cdrecord $CDRECORDGLOB $CDRECORDOPTS *.wav

# Clean up.
rm -rf $BURNDIR/*
