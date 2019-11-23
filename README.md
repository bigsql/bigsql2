# README for BIGSQL2 ( http://bigsql.org ) #

Recipe for making the "Postgres by BigSQL" distro.

## Pre-reqs for CentOS 7 #####################################
sudo yum update -y
sudo yum install -y git 
sudo yum install -y epel-release
sudo yum install -y net-tools zip unix2dos wget bzip2 python-pip
sudo yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel

## Steps to configure new components ######################################

* Update env.sh with the current (new) version #
* Update versions.sql to include the new version #'s and mark prior version as not current
* Ensure file in $IN
* Remove files from $OUT (including the checksum file for the component)
* run build_all.sh

