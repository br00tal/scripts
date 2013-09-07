#!/bin/sh

# Variables
HOSTNAME=`hostname`
TIME=`date`
DATE=`date +"%Y%m%d"`
BACKUPDIR=/mnt/backup
BACKUPLOG=$BACKUPDIR/$HOSTNAME-$DATE.log

# Print initial script start time
echo "Backup of $HOSTNAME starting at $TIME" >> $BACKUPLOG

# Create required directories and such
mkdir $BACKUPDIR/$HOSTNAME-$DATE
cd $BACKUPDIR

# Keep four backups total, and remove anything older
echo "Removing old backups for $HOSTNAME" >> $BACKUPLOG
ls -t ${HOSTNAME}*.tar.xz | sed -e '1,3d' | xargs -d '\n' rm

# Start the rsync operation
echo "Starting the rsync operation for $HOSTNAME" >> $BACKUPLOG
START=$(date +%s)
rsync -aAXv /* $BACKUPDIR/$HOSTNAME-$DATE --exclude dev/* --exclude proc/* --exclude sys/* --exclude tmp/* --exclude run/* --exclude mnt/* --exclude media/* --exclude lost+found --exclude var/lib/pacman/sync/*

# Convert the directory to an xz archive for space purposes
echo "Starting the compression operation for $HOSTNAME" >> $BACKUPLOG
cd $BACKUPDIR
tar -c --xz -f $HOSTNAME-$DATE.tar.xz $HOSTNAME-$DATE
rm -rf $HOSTNAME-$DATE

# Return the total time from rsync to tar completion
FINISH=$(date +%s)
echo "Backup of $HOSTNAME complete.  Total run time: $(( ($FINISH-$START) / 60 )) minutes, $(( ($FINISH-$START) % 60 )) seconds"
