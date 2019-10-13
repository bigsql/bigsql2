# README for BIGSQL2 ( http://bigsql.org ) #

Recipe for making the "Postgres by BigSQL" distro.

## Pre-reqs for CentOS 7 #####################################
```
sudo yum update -y
sudo yum install -y git 
sudo yum install -y net-tools zip unix2dos wget bzip2 python-pip
sudo yum install -y epel-release
sudo yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel

## Setup dev environment ####################################
```
# make the basic APG directory structure under your $HOME directory
mkdir ~/dev
mkdir ~/dev/in
mkdir ~/dev/out
mkdir ~/dev/apg_history

# pull in from git the BIGSQL2 project & then APG underneath it
cd ~/dev
git clone https://github.com/bigsql/bigsql2  
cd bigsql
git clone https://github.com/bigsql/apg

# edit your ~/.bashrc to set env variables
export DEV=$HOME/dev
export HIST=$DEV/apg_history
export IN=$DEV/in
export OUT=$DEV/out

export APG=$DEV/bigsql2
export DEVEL=$APG/devel
export PG=$DEVEL/pg
export PGBIN=$DEVEL/pgbin

export SRC=$IN/sources
export BLD=/opt/pgbin-build/pgbin/bin

export CLI=$APG/apg/scripts
export PSX=$APG/out/posix
export REPO=http://localhost:8000

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$PATH:$JAVA_HOME/bin

## Steps to configure new components ######################################

* Update env.sh with the current (new) version #
* Update versions.sql to include the new version #'s and mark prior version as not current
* Ensure file in $IN
* Remove files from $OUT (including the checksum file for the component)
* run build_all.sh

## Steps to setup an environment to compile components ###############
sudo mkdir /opt/pgbin-build
chmod 777 /opt/pgbin-build
sudo chown $USER:$USER /opt/pgbin-build
mkdir /opt/pgbin-build/pgbin
mkdir /opt/pgbin-build/pgbin/bin




