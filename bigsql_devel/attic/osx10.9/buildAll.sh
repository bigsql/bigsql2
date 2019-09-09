#!/bin/bash
#
upLoadTo118=0
pgBinSources=/opt/pgbin-build/sources
pgBinBuilds=/opt/pgbin-build/builds
source ./versions.sh

echo "Build PostgreSQL : $pg11V-$pg11BuildV"
#./pgbin-osx.sh -a $pgBinBuilds -t $pgBinSources/postgresql-$pg11V.tar.gz -n $pg11BuildV
if [[ $? -eq 0 ]]; then
	echo "Build Completed Successfully ...."
else
	echo "Build Failed"	
fi
echo "================================================"
echo""


echo "Build PostgreSQL : $pg10V-$pg10BuildV"
#./pgbin-osx.sh -a $pgBinBuilds -t $pgBinSources/postgresql-$pg10V.tar.gz -n $pg10BuildV
if [[ $? -eq 0 ]]; then
	echo "Build Completed Successfully ...."
else
	echo "Build Failed"	
fi
echo "================================================"
echo""

#exit 0
echo "Build PostgreSQL : $pg96V-$pg96BuildV"
./pgbin-osx.sh -a $pgBinBuilds -t $pgBinSources/postgresql-$pg96V.tar.gz -n $pg96BuildV
if [[ $? -eq 0 ]]; then
	echo "Build Completed Successfully ...."
else
	echo "Build Failed"	
fi
echo "================================================"
echo""


echo "Build PostgreSQL : $pg95V-$pg95BuildV"
./pgbin-osx.sh -a $pgBinBuilds -t $pgBinSources/postgresql-$pg95V.tar.gz -n $pg95BuildV
if [[ $? -eq 0 ]]; then
        echo "Build Completed Successfully ...."
else
        echo "Build Failed"     
fi
echo "================================================"
echo""

echo "Build PostgreSQL : $pg94V-$pg94BuildV"
./pgbin-osx.sh -a $pgBinBuilds -t $pgBinSources/postgresql-$pg94V.tar.gz -n $pg94BuildV 
if [[ $? -eq 0 ]]; then
        echo "Build Completed Successfully ...."
else
        echo "Build Failed"     
fi
echo "================================================"
echo""

