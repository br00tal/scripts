#!/bin/sh
#
# flacgain.sh - Set the ReplayGain on all flac files in a set
#               of subdirectories underneath $DIR.
#

# The parent directory to look for flac files in
DIR=$1

# Find all subdirectories underneath $DIR
find $DIR -type d | while read i; do
  # Check each subdirectory for flac files
  FLACDIR=`find "$i" -type f -maxdepth 1 -name "*.flac" | wc -l`
  # If more than one flac file exists, continue on
  if [ "$FLACDIR" -gt "1" ]; then
    echo "Directory $i contains $FLACDIR flac files."
    # Check to see if ReplayGain has already been applied
    RGFILETEST=`ls "$i"/*.flac | head -1`
    RGTEST=`metaflac --list --block-type=VORBIS_COMMENT "$RGFILETEST" | grep REPLAYGAIN`
    # If no ReplayGain, go ahead and apply it
    if [ "$RGTEST" == "" ]; then
      echo "Adding ReplayGain to them..."
      metaflac --add-replay-gain "$i"/*.flac
    # If ReplayGain is found, skip the files in that directory
    else
      echo "Files in $i appear to have ReplayGain applied already, skipping..."
    fi
  fi
done
