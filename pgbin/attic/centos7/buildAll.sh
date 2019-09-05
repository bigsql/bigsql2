#!/bin/bash
#

upLoadTo118=0
pgSrc=/opt/pgbin-build/sources/postgresql
binBld=/opt/pgbin-build/builds
source ./versions.sh

function runPgBinLinux {
  pOutDir=$1
  pPgSrc=$2
  pBldV=$3

  bncrSrc=$SRC/pgbouncer-1.9.0.tar.gz
  odbcSrc=$SRC/psqlodbc-11.01.0000.tar.gz

  ./pgbin-linux.sh -a $pOutDir -t $pPgSrc -n $pBldV -b $bncrSrc -o $odbcSrc
  
  if [[ $? -eq 0 ]]; then
	echo "Build Completed Successfully ...."
  else
	echo "Build Failed"
	exit 1	
  fi

  echo "================================================"
  echo""
  return
}

########################################################################
##                     MAINLINE                                       ##
########################################################################

tgz="tar.gz"

#runPgBinLinux "$binBld" "$pgSrc-$pg11V.$tgz" "$pg11BuildV"
runPgBinLinux "$binBld" "$pgSrc-$pg10V.$tgz" "$pg10BuildV"
runPgBinLinux "$binBld" "$pgSrc-$pg12V.$tgz" "$pg12BuildV"

# BDR
#runPgBinLinux "$binBld" "$pgSrc-$pg94V.$tgz" "$pg94BuildV"

exit
