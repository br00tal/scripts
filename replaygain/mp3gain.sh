#!/bin/sh
#
# mp3gain.sh - Set the ReplayGain on all mp3 files in a set
#               of subdirectories underneath $DIR.
#

# The parent directory to look for mp3 files in
DIR=$1

# Find all subdirectories underneath $DIR
find $DIR -type d | while read i; do
  # Check each subdirectory for mp3 files
  MP3DIR=`find "$i" -type f -maxdepth 1 -name "*.mp3" | wc -l`
  # If more than one mp3 file exists, continue on
  if [ "$MP3DIR" -gt "1" ]; then
    echo "Directory $i contains $MP3DIR mp3 files."
    # Check to see if ReplayGain has already been applied
    RGFILETEST=`ls "$i"/*.mp3 | head -1`
    RGTEST=`mp3gain -s c "$RGFILETEST" | grep gain`
    # If no ReplayGain, go ahead and apply it
    if [ "$RGTEST" == "" ]; then
      echo "Adding ReplayGain to them..."
      mp3gain "$i"/*.mp3
    # If ReplayGain is found, skip the files in that directory
    else
      echo "Files in $i appear to have ReplayGain applied already, skipping..."
    fi
  fi
done
