#!/bin/bash
#
upLoadTo118=1
pgBinSources=/opt/pgbin-build/sources
pgBinBuilds=/opt/pgbin-build/builds
source ./versions.sh

echo "Build Components for PG : $pg96V-$pg96BuildV"
./pgbin-linux.sh -a $pgBinBuilds -t $pgBinSources/postgresql-$pg96V.tar.gz -n $pg96BuildV 
if [[ $? -eq 0 ]]; then
	echo "Build Completed Successfully ...."
else
	echo "Build Failed"	
fi

echo "Build Components for PG : $pg95V-$pg95BuildV"
./pgbin-
if [[ $? -eq 0 ]]; then
        echo "Build Completed Successfully ...."
else   
        echo "Build Failed"     
fi
