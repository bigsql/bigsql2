# README for BIGSQL2 ( http://bigsql.org ) #

Recipe for making the "Postgres by BigSQL" distro.

## Pre-reqs for CentOS 7 w/ Python 3.7 #######################
```
sudo yum update -y
sudo yum install -y git net-tools zip unix2dos wget bzip2 pbzip2 openssh-server

sudo yum install -y epel-release
sudo yum install -y awscli

sudo yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel openssh-server
ANT=apache-ant-1.9.14-bin.tar.gz
cd ~
wget http://mirror.reverse.net/pub/apache/ant/binaries/$ANT
tar -xvf $ANT
rm $ANT

sudo yum install -y gcc openssl-devel bzip2-devel libffi libffi-devel
wget https://www.python.org/ftp/python/3.7.4/Python-3.7.4.tgz
tar -xzf Python-3.7.4.tgz 
cd Python-3.7.4/
sudo ./configure --enable-optimizations
sudo make install

pip3 install --upgrade pip --user
pip3 install pssh --user

cd ~
ssh-keygen -t rsa
cd .ssh
cat id_rsa.pub
< paste into authorized_keys of remote server >
```

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

export NIMOY=$DEV/nimoy
export RMT=$NIMOY/remote

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
export ANT_HOME=~/apache-ant-1.9.14
export PATH=$PATH:$JAVA_HOME/bin:$ANT_HOME/bin

## Steps to make new components ######################################

* Update env.sh with the current (new) version #
* Update versions.sql to include the new version #'s and mark prior version as not current
* Ensure file in $IN
* Remove files from $OUT (including the checksum file for the component)
* run build_all.sh

