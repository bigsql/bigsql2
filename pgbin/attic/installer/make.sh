#!/bin/bash
#make.sh

#BITDIR=/Applications/BitRock\ InstallBuilder\ Professional\ 15.10.1
#BITDIR=/Applications/BitRock\ InstallBuilder\ Professional\ 16.4.0
BITDIR=/home/build/installbuilder-16.7.0/

MYDIR=$(dirname $BASH_SOURCE)

source $MYDIR/ohai.sh
source $MYDIR/env.sh
if [ -e "$MYDIR/local-env.sh" ]
then
  source $MYDIR/local-env.sh
fi

printusage() {
  echo "Usage: $0 [-v version] [-p platform] [-c]"
  echo "  -v  PostgreSQL component version number {pg11, pg10, pg96, pg95, pg94, all}. Default is 'all'."
  echo "  -p  Platform {win64, osx64, or all} Default is 'all'."
  echo "  -c  Clean the output directory prior to building. If not set, no clean."
  echo "  Runs the BitRock command line InstallBuilder program to generate BigSQL installers for OSX and Windows"
}


VER=all
PLAT=all
CLEAN=false
while getopts v:p:ch opt
do
  case "$opt" in
    v)  VER="$OPTARG";;
    p)  PLAT="$OPTARG";;
    c)  CLEAN=true;;
    h) printusage
      exit 1;;
    \?)		# unknown flag
        printusage
        exit 1;;
  esac
done

case "$PLAT" in
  win64) WIN64=1; OSX64=0;;
  osx64) WIN64=0; OSX64=1;;
  all) WIN64=1; OSX64=1;;
  *) #unknown platform
      warn Unknown platform "$PLAT"
      printusage
      exit 1;;
esac

case "$VER" in
  all) pg11=1; pg10=1; pg96=1; pg95=1; pg94=1;;
  pg11) pg11=1; pg10=0; pg96=0; pg95=0; pg94=0;;
  pg10) pg11=0; pg10=1; pg96=0; pg95=0; pg94=0;;
  pg96) pg11=0; pg10=0; pg96=1; pg95=0; pg94=0;;
  pg95) pg11=0; pg10=0; pg96=0; pg95=1; pg94=0;;
  pg94) pg11=0; pg10=0; pg96=0; pg95=0; pg94=1;;
  *) #unknown version
      warn Unknown version \"$VER\"
      printusage
      exit 1;;
esac

cd $MYDIR/..

if [ "true" == "$CLEAN" ]; then
  doit scripts/clean_output.sh
fi

## OSX 64 ##
if [ 1 -eq $OSX64 ]; then

  if [ 1 -eq $pg11 ]; then
    doit scripts/prep_sandbox.sh -v $P11b -p osx64 -e
    "$BITDIR/bin/builder" build postgresql.xml osx --setvars version_file_name="pg11.properties" build_identifier="$P11b" bam4b="$bam4b"
  fi

  if [ 1 -eq $pg10 ]; then
    doit scripts/prep_sandbox.sh -v $P10b -p osx64 -e
    "$BITDIR/bin/builder" build postgresql.xml osx --setvars version_file_name="pg10.properties" build_identifier="$P10b" bam4b="$bam4b"
  fi

  if [ 1 -eq $pg96 ]; then
    doit scripts/prep_sandbox.sh -v $P96b -p osx64 -e
    "$BITDIR/bin/builder" build postgresql.xml osx --setvars version_file_name="pg96.properties" build_identifier="$P96b" bam4b="$bam4b"
  fi

  if [ 1 -eq $pg95 ]; then
    doit scripts/prep_sandbox.sh -v $P95b -p osx64 -e
    "$BITDIR/bin/builder" build postgresql.xml osx --setvars version_file_name="pg95.properties" build_identifier="$P95b" bam4b="$bam4b"
  fi

  if [ 1 -eq $pg94 ]; then
    doit scripts/prep_sandbox.sh -v $P94b -p osx64 -e
    "$BITDIR/bin/builder" build postgresql.xml osx --setvars version_file_name="pg94.properties" build_identifier="$P94b" bam4b="$bam4b"
  fi

fi


## WINDOWS ##
if [ 1 -eq $WIN64 ]; then
  # a blank windowsSigningPkcs12File tells BitRock to not sign the installer
  # so that it can be signed using the Extended verification USB fob

  # require_admin on Windows, but not on OS X

  if [ 1 -eq $pg11 ]; then
    doit scripts/prep_sandbox.sh -v $P11b -p win64 -e
    "$BITDIR/bin/builder" build postgresql.xml windows --setvars version_file_name="pg11.properties" require_admin="1" build_identifier="$P11b"  bam4b="$bam4b" project.windowsSigningPkcs12File=""
  fi

  if [ 1 -eq $pg10 ]; then
    doit scripts/prep_sandbox.sh -v $P10b -p win64 -e
    "$BITDIR/bin/builder" build postgresql.xml windows --setvars version_file_name="pg10.properties" require_admin="1" build_identifier="$P10b"  bam4b="$bam4b" project.windowsSigningPkcs12File=""
  fi

  if [ 1 -eq $pg96 ]; then
    doit scripts/prep_sandbox.sh -v $P96b -p win64 -e
    "$BITDIR/bin/builder" build postgresql.xml windows --setvars version_file_name="pg96.properties" require_admin="1" build_identifier="$P96b"  bam4b="$bam4b" project.windowsSigningPkcs12File=""
  fi

  if [ 1 -eq $pg95 ]; then
    doit scripts/prep_sandbox.sh -v $P95b -p win64 -e
    "$BITDIR/bin/builder" build postgresql.xml windows --setvars version_file_name="pg95.properties" require_admin="1" build_identifier="$P95b"  bam4b="$bam4b" project.windowsSigningPkcs12File=""
  fi

  if [ 1 -eq $pg94 ]; then
    doit scripts/prep_sandbox.sh -v $P94b -p win64 -e
    "$BITDIR/bin/builder" build postgresql.xml windows --setvars version_file_name="pg94.properties" require_admin="1" build_identifier="$P94b" bam4b="$bam4b" project.windowsSigningPkcs12File=""
  fi

  if [ 1 -eq $pg93 ]; then
    doit scripts/prep_sandbox.sh -v $P93b -p win64 -e
    "$BITDIR/bin/builder" build postgresql.xml windows --setvars version_file_name="pg93.properties" require_admin="1" build_identifier="$P93b" bam4b="$bam4b" project.windowsSigningPkcs12File=""
  fi

  if [ 1 -eq $pg92 ]; then
    doit scripts/prep_sandbox.sh -v $P92b -p win64 -e
    "$BITDIR/bin/builder" build postgresql.xml windows --setvars version_file_name="pg92.properties" require_admin="1" build_identifier="$P92b" bam4b="$bam4b" project.windowsSigningPkcs12File=""
  fi
fi

rm -rf "$MYDIR"/../output/PostgreSQL-*.app
