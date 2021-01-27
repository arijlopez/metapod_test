#!/bin/bash -xe
# example use:
# bash get_jenkins_backup_from_container.sh /projects/metapod metapod_jenkins
# run this script while holmes_jenkins container is running to make a backup of plugins,config,etc
metapod_home=$1
jenkins_container_name=$2

jenkins_backup=${metapod_home}/jenkins/files/jenkins_backup
tmp=${jenkins_backup}/tmp
tmp_jenkins_home=${tmp}/jenkins_home

rm -rf ${tmp}
mkdir -p ${tmp}

docker cp ${jenkins_container_name}:/var/jenkins_home/ ${tmp}

# remove jenkins logs
rm -rf ${tmp_jenkins_home}/logs/*

# remove builds but not legacyIds and
rm -rf ${tmp_jenkins_home}/jobs/run_inspec/builds/*
rm -rf ${tmp_jenkins_home}/workspace/*
rm -rf ${tmp_jenkins_home}/war/*
rm -rf ${tmp_jenkins_home}/data/reports/*
echo "1" > ${tmp_jenkins_home}/jobs/run_inspec/nextBuildNumber
cp ${tmp_jenkins_home}/jobs/run_inspec/config.xml ${metapod_home}/jenkins/files/run_inspec/

cd ${tmp}/jenkins_home
zip -s 25m -r jenkins_backup_latest_split.zip .
mv jenkins_backup_latest* ${jenkins_backup}

rm -rf ${tmp}
