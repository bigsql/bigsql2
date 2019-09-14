#!/bin/bash
#

pgSrc=/opt/pgbin-build/sources/postgresql
binBld=/opt/pgbin-build/builds
source ./versions.sh

function runPgBin {
  pOutDir=$1
  pPgSrc=$2
  pBldV=$3

  bncrSrc=$SRC/pgbouncer-$bouncerV.tar.gz
  odbcSrc=$SRC/psqlodbc-$odbcV.tar.gz
  bkrstSrc=$SRC/backrest-$backrestV.tar.gz

  ./build-pgbin.sh -a $pOutDir -t $pPgSrc -n $pBldV
  #./build-pgbin.sh -a $pOutDir -t $pPgSrc -n $pBldV -b $bncrSrc -o $odbcSrc -k $bkrstSrc
  if [[ $? -ne 0 ]]; then
    echo "Build Failed"
    exit 1	
  fi

  return
}

########################################################################
##                     MAINLINE                                       ##
########################################################################

tgz="tar.gz"

#runPgBin "$binBld" "$pgSrc-$pg10V.$tgz" "$pg10BuildV"
runPgBin "$binBld" "$pgSrc-$pg11V.$tgz" "$pg11BuildV"
#runPgBin "$binBld" "$pgSrc-$pg12V.$tgz" "$pg12BuildV"

# BDR
#runPgBin "$binBld" "$pgSrc-$pg94V.$tgz" "$pg94BuildV"

exit
