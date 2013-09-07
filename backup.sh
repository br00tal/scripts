#!/bin/sh

# Variables
HOSTNAME=`hostname`
DATE=`date +"%Y%m%d"`
BACKUPDIR=/mnt/backup

# Create required directories and such
mkdir $BACKUPDIR/$HOSTNAME-$DATE
cd $BACKUPDIR

# Keep four backups total, and remove anything older
ls -t ${HOSTNAME}*.tar.xz | sed -e '1,3d' | xargs -d '\n' rm

# Start the rsync operation
START=$(date +%s)
rsync -aAXv /* $BACKUPDIR/$HOSTNAME-$DATE --exclude dev/* --exclude proc/* --exclude sys/* --exclude tmp/* --exclude run/* --exclude mnt/* --exclude media/* --exclude lost+found --exclude var/lib/pacman/sync/*
FINISH=$(date +%s)
echo "total time: $(( ($FINISH-$START) / 60 )) minutes, $(( ($FINISH-$START) % 60 )) seconds"

# Convert the directory to an xz archive for space purposes
cd $BACKUPDIR
tar -c --xz -f $HOSTNAME-$DATE.tar.xz $HOSTNAME-$DATE
rm -rf $HOSTNAME-$DATE
