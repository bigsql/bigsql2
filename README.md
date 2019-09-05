# README for BIGSQL #

Recipe for the "Postgres by BigSQL" distro http://bigsql.org

## Pre-reqs #################################################
```
sudo yum install -y net-tools zip unix2dos wget git python-setuptools bzip2 pbzip2 awscli java-1.8.0-openjdk java-1.8.0-openjdk-devel openssh-server python-pip

sudo pip install --upgrade pip
sudo pip install pssh

ssh-keygen -t rsa
cd ~/.ssh
cat id_rsa.pub
< paste into authorized_keys of remote server >
```

## Setup dev environment ####################################
```
# make the basic PGC directory structure under your $HOME directory
mkdir ~/pgc
mkdir ~/pgc/in
mkdir ~/pgc/out

# pull in from git the BIGSQL project & then PGCLI underneath it
cd ~/pgc
git clone https://github.com/bigsql/bigsql.git 
cd bigsql
git clone https://github.com/bigsql/pgcli

# edit your ~/.bashrc to set required IN & OUT env variables
export IN=$HOME/pgc/in
export OUT=$HOME/pgc/out
export PGC=$HOME/pgc/bigsql
export CLI=$PGC/pgcli/scripts
export REPO=http://localhost:8000

## Steps to make new components ######################################

* Update env.sh with the current (new) version #
* Update versions.sql to include the new version #'s and mark prior version as not current
* Ensure file in $IN
* Remove files from $OUT (including the checksum file for the component)
* run build_all.sh

