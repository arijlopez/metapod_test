#!/bin/bash
# How to run:
# ./jenkins_backup.sh /projects/jenkins_volume  /projects/test/jenkins_project
JENKINS_HOME=$1
JENKINS_BACKUPS=$2
BACKUP_NAME=jenkins_backup_`date +"%Y%m%d%H%M%S"`
cd $JENKINS_BACKUPS
git clone https://github.com/sue445/jenkins-backup-script
cd jenkins-backup-script
./jenkins-backup.sh $JENKINS_HOME $JENKINS_BACKUPS/$BACKUP_NAME.tar.gz

cd $JENKINS_BACKUPS

tar zxvf $BACKUP_NAME.tar.gz
cd jenkins-backup
zip -s 20m -r jenkins_backup_latest_split.zip .
mv jenkins_backup_latest* $JENKINS_BACKUPS
rm -rf jenkins-backup
rm -rf $JENKINS_BACKUPS/jenkins-backup-script
# keep backup with latest 30 days
#find $JENKINS_BACKUPS_* -mtime +10 -delete
