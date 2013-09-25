#!/bin/sh
# backup.sh - A script to backup systems via rsync and tar.
#
# Written by br00tal
#

# Directories to *exclude* during backups.
DIRS="/dev /proc /sys /tmp /run /mnt /media /lost+found /var/lib/pacman/sync \
/var/cache/pacman/pkg /auto"

# Compression method.  Valid values are xz, bzip2, and gzip.
COMP="xz"

# How many backups do you want to keep?
KEEP="3"

# Where to save the backups to.
BACKUPDIR=/mnt/backup

# You shouldn't really need to change the below variables.
HOSTNAME=`hostname`
TIME=`date`
DATE=`date +"%Y%m%d"`
BACKUPLOG=$BACKUPDIR/$HOSTNAME-$DATE.log
RSYNCOPTS="-aAXv --progress"

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
if [ "$LOGCOUNT" -gt "$KEEP" ]; then
  logline "Removing old logs for $HOSTNAME" >> $BACKUPLOG
  ls -t ${HOSTNAME}*.log | sed -e "1,${KEEP}d" | xargs -d '\n' rm
fi

# Convert excluded directories to rsync format.
EXCLUDE=()
EXCOUNT=0
for z in $DIRS; do
  DIR=`echo $z | cut -c 2-`
  EXCLUDE[$EXCOUNT]=`echo "--exclude $DIR/*"`
  EXCOUNT=$(( $EXCOUNT + 1 ))
done

# Start the rsync operation
logline "Starting the rsync operation for $HOSTNAME" >> $BACKUPLOG
START=$(date +%s)
rsync $RSYNCOPTS /* $BACKUPDIR/$HOSTNAME-$DATE ${EXCLUDE[@]}

# Convert the directory to an xz archive for space purposes
logline "Starting the compression operation for $HOSTNAME" >> $BACKUPLOG
cd $BACKUPDIR
tar -c --$COMP -f $HOSTNAME-$DATE.tar.$EXT $HOSTNAME-$DATE
rm -rf $HOSTNAME-$DATE

# Return the total time from rsync to tar completion
FINISH=$(date +%s)
logline "Backup of $HOSTNAME complete.  Total run time: \
$(( ($FINISH-$START) / 60 )) minutes, $(( ($FINISH-$START) % 60 )) \
seconds." >> $BACKUPLOG

