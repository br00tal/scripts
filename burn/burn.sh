#!/bin/sh
#
# burn.sh - a script to decode and write .flac, .mp3, and .wav files to CD-Rs.
#
# Written by br00tal.
#

# Temporary directory to hold generated .wav files for burning.
BURNDIR=/tmp/burn
# CD-ROM device.  Leave blank if you want to try to auto-detect.
DEVICE=
# The burning speed.  Default is 48.
SPEED=48

# Usage
usage() {
cat <<EOF
usage: $0 options

Specify only one option at a time.

Options:
  -f   Burn flac files
  -m   Burn mp3 files
  -w   Burn wav files
EOF
}

# Need an argument.  Exit if nothing.
if [ "X$1" == "X" ]; then
  echo "No option specified."
  usage
  exit 1
fi

isFLAC="false"
isMP3="false"
isWAV="false"

while getopts "fmw" OPTION; do
  case $OPTION in
    f ) TYPE="FLAC"; isFLAC="true";;
    m ) TYPE="MP3"; isMP3="true";;
    w ) TYPE="WAV"; isWAV="true";;
    * ) usage; exit 1;;
  esac
done

# Make sure we are using only one option at a time.
if [ "$isFLAC" == "true" -a "$isMP3" == "true" ]; then
  echo "-f and -m are exclusive.  Please only specify one argument at a time."
  exit 1
elif [ "$isFLAC" == "true" -a "$isWAV" == "true" ]; then
  echo "-f and -w are exclusive.  Please only specify one argument at a time."
  exit 1
elif [ "$isMP3" == "true" -a "$isWAV" == "true" ]; then
  echo "-m and -w are exclusive.  Please only specify one argument at a time."
  exit 1
fi

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
getFiles() {
CLEANDIR=`ls $BURNDIR`
if [ "X$CLEANDIR" != "X" ]; then
  rm -rf $BURNDIR/*
fi
if [ ! -d "$BURNDIR" ]; then
  mkdir -p $BURNDIR
fi
echo -n "Enter the path containing the .flac files: "
read -e LOC
}

# Copy files to $BURNDIR and decode to .wav files.
copyFLAC() {
cp "$LOC"/*.flac $BURNDIR/
cd $BURNDIR
flac -d *.flac
}

copyMP3() {
cp "$LOC"/*.mp3 $BURNDIR/
cd $BURNDIR
IFS=$(echo)
for j in *.mp3; do
        CDR=`basename "$j" .mp3`
        mpg123 -w $CDR.wav $j
done
unset IFS
}

copyWAV() {
cp "$LOC"/*.wav $BURNDIR/
}

# Finally, write the .wav files to the CD-R.
burnFiles() {
cd $BURNDIR
sudo cdrecord $CDRECORDGLOB $CDRECORDOPTS *.wav
rm -rf $BURNDIR/*
}

getFiles
copy$TYPE
burnFiles
