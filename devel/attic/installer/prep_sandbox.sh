#!/bin/bash

#basic shell script to pull developer sandbox builds
#and unzip them to the directory structure needed for BitRock

printusage() {
  echo "Usage: $0 -v version [-d] [-e] [-p platform]"
  echo "  -v  Sanbox build version string (ex. 9.5.1-1)"
  echo "  -d  Download from S3 (default false)"
  echo "  -e  Extract (default false) (if false, really just for downloading)"
  echo "  -p  Platform {win64, osx64, or all} Default is all"
  echo "Downloads bigsql sandbox from s3://oscg-downloads/packages"
}

#helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
WHITE='\033[0;39m'
NC='\033[0m' # No Color
ohai() {
  printf "${BLUE}==>${WHITE} $@ ${NC}\n"
}


warn() {
  printf "${RED}Warning${WHITE}: $@ ${NC}\n"
}

doit() {
  ohai "$@"
  $@
}

VER=
PLAT=all
DOWNLOAD=false
EXTRACT=false
while getopts v:p:ed opt
do
  case "$opt" in
    v)  VER="$OPTARG";;
    p)  PLAT="$OPTARG";;
    d)  DOWNLOAD=true;;
    e)  EXTRACT=true;;
    \?)		# unknown flag
        printusage
        exit 1;;
  esac
done

if [ -z "$VER" ]; then
  warn Missing required version argument
  printusage
  exit 1
fi

case "$PLAT" in
  win64) WIN64=1; OSX64=0;;
  osx64) WIN64=10; OSX64=1;;
  all) WIN64=1; OSX64=1;;
  *) #unknown platform
      warn Unknown platform "$PLAT"
      printusage
      exit 1;;
esac

#ohai "Ver: $VER"
#ohai "Plat: $PLAT"
#ohai "Download: $DOWNLOAD"
#ohai "Extract: $EXTRACT"

cd $(dirname $BASH_SOURCE)/../sandboxes

if [ 1 -eq $WIN64 ]; then
  WINFILE=bigsql-$VER-win64.zip
  cd win64
  if [ "true" = "$DOWNLOAD" ]; then
    ohai "Pulling $VER WIN64: $WINFILE"
    aws s3 cp s3://oscg-downloads/packages/$WINFILE .
  fi
  if [ "true" = "$EXTRACT" ]; then
    rm -rf bigsql
    unzip -q $WINFILE
    #copy the images folder under conf
    cp -R ../images bigsql/conf/.
    #copy the installer scripts for OSX
    mkdir bigsql/installerscripts
    cp -R ../../scripts/win64/*.* bigsql/installerscripts/.
  fi

  cd ..
fi

if [ 1 -eq $OSX64 ]; then
  OSXFILE=bigsql-$VER-osx64.tar.bz2
  cd osx64
  if [ "true" = "$DOWNLOAD" ]; then
    ohai "Pulling $VER OSX64: $OSXFILE"
    aws s3 cp s3://oscg-downloads/packages/$OSXFILE .
  fi
  if [ "true" = "$EXTRACT" ]; then
    rm -rf bigsql
    tar -xjf $OSXFILE
    #copy the images folder under conf
    cp -R ../images bigsql/conf/.
    #copy the installer scripts for OSX
    mkdir bigsql/installerscripts
    cp -R ../../scripts/osx64/*.* bigsql/installerscripts/.
  fi

  cd ..
fi
