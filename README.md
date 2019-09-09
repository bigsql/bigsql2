# README for BIGSQL2 #

Recipe for the "Postgres by BigSQL" distro http://bigsql.org

## Pre-reqs #################################################
```

sudo yum install -y net-tools zip unix2dos wget git bzip2 pbzip2 
sudo yum install -y awscli java-1.8.0-openjdk java-1.8.0-openjdk-devel openssh-server

cd ~

wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo rpm -ivh epel-release-latest-7.noarch.rpm
sudo yum install -y python-setuptools python-pip
sudo pip install pssh

ssh-keygen -t rsa
cd .ssh
cat id_rsa.pub
< paste into authorized_keys of remote server >
```

## Setup dev environment ####################################
```
# make the basic PGC directory structure under your $HOME directory
mkdir ~/dev
mkdir ~/dev/in
mkdir ~/dev/out

# pull in from git the BIGSQL2 project & then PGC underneath it
cd ~/dev
git clone https://github.com/bigsql/bigsql2  
cd bigsql
git clone https://github.com/bigsql/cli2

# edit your ~/.bashrc to set env variables
export DEV=$HOME/dev
export PG=$DEV/pg

export HIST=$DEV/pgc_history
export IN=$DEV/in
export OUT=$DEV/out
export PGC=$DEV/bigsql2
export CLI=$PGC/cli2/scripts
export PSX=$PGC/out/posix
export REPO=http://localhost:8000

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$PATH:$JAVA_HOME/bin

export ANT_HOME=$HOME/apache-ant-1.9.14
export PATH=$ANT_HOME/bin:$PATH


## Steps to make new components ######################################

* Update env.sh with the current (new) version #
* Update versions.sql to include the new version #'s and mark prior version as not current
* Ensure file in $IN
* Remove files from $OUT (including the checksum file for the component)
* run build_all.sh

