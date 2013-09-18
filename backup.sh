#!/bin/sh
# backup.sh - A script to backup systems via rsync and tar.
#
# Written by br00tal
#

# Variables
HOSTNAME=`hostname`
TIME=`date`
DATE=`date +"%Y%m%d"`
BACKUPDIR=/mnt/backup
BACKUPLOG=$BACKUPDIR/$HOSTNAME-$DATE.log
RSYNCOPTS="-aAXv --progress"

# Compression method.  Valid values are xz, bzip2, and gzip.
COMP="xz"

# How many backups do you want to keep?
KEEP="3"

if [ "$COMP" == "xz" ]; then
  EXT="xz"
elif [ "$COMP" == "bzip2" ]; then
  EXT="bz2"
elif [ "$COMP" == "gzip" ]; then
  EXT="gz"
else
  echo "Invalid compression method.  Exiting..."
  exit 1
fi

logline () {
   message=$1
   echo "[`date +%m/%d/%y\ %H:%M:%S`] $message"
}

# Print initial script start time
logline "Backup of $HOSTNAME starting..." >> $BACKUPLOG

# Create required directories and such
mkdir $BACKUPDIR/$HOSTNAME-$DATE
cd $BACKUPDIR

# Keep <n> backups total, and remove anything older
DELCOUNT=$(($KEEP - 1))
BACKUPCOUNT=`ls ${HOSTNAME}*.tar.$EXT | wc -l`
if [ "$BACKUPCOUNT" -ge "$KEEP" ]; then
  logline "Removing old backups for $HOSTNAME" >> $BACKUPLOG
  ls -t ${HOSTNAME}*.tar.$EXT | sed -e "1,${DELCOUNT}d" | xargs -d '\n' rm
fi
LOGCOUNT=`ls ${HOSTNAME}*.log | wc -l`
if [ "$LOGCOUNT" -ge "$KEEP" ]; then
  logline "Removing old logs for $HOSTNAME" >> $BACKUPLOG
  ls -t ${HOSTNAME}*.log | sed -e "1,${DELCOUNT}d" | xargs -d '\n' rm
fi

# Start the rsync operation
logline "Starting the rsync operation for $HOSTNAME" >> $BACKUPLOG
START=$(date +%s)
rsync $RSYNCOPTS /* $BACKUPDIR/$HOSTNAME-$DATE --exclude dev/* \
  --exclude proc/* --exclude sys/* --exclude tmp/* --exclude run/* \
  --exclude mnt/* --exclude media/* --exclude lost+found \
  --exclude var/lib/pacman/sync/* --exclude var/cache/pacman/pkg/*

# Convert the directory to an xz archive for space purposes
logline "Starting the compression operation for $HOSTNAME" >> $BACKUPLOG
cd $BACKUPDIR
tar -c --$COMP -f $HOSTNAME-$DATE.tar.$EXT $HOSTNAME-$DATE
rm -rf $HOSTNAME-$DATE

# Return the total time from rsync to tar completion
FINISH=$(date +%s)
logline "Backup of $HOSTNAME complete.  Total run time: $(( ($FINISH-$START) / 60 )) minutes, $(( ($FINISH-$START) % 60 )) seconds." >> $BACKUPLOG

