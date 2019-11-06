#!/bin/bash
#
# This script generates a relocatable build for PostgreSQL and optionally includes
#   building pgbouncer, psqlodbc, and pgbackrest
#
# The PostgreSQL build includes all the contrib modules, support for libreadline, 
#   libz & openssl.
#
# The script requires OpenSSL, Libreadline, termcap, libz etc available under $sharedLibs
#

#set -x

archiveDir="/opt/builds/"
baseDir="`pwd`/.."
workDir=`date +%Y%m%d_%H%M`
buildLocation=""

osArch=`getconf LONG_BIT`
 
sharedLibs="$baseDir/shared/linux_$osArch/lib"
sharedBins="$baseDir/shared/linux_$osArch/bin"
includePath="$baseDir/shared/linux_$osArch/include"
export R_HOME=/opt/pgbin-build/pgbin/shared/linux_64/R323/lib64/R

pgTarLocation=""
pgSrcDir=""
pgSrcV=""
pgShortV=""
pgBldV=1
pgLLVM=""

sourceTarPassed=0
archiveLocationPassed=0
buildVersionPassed=0
buildBouncer=0
buildODBC=0
buildBackrest=0

scriptName=`basename $0`


function printUsage {
echo "
Usage:

$scriptName [OPTIONS]

Required Options:
	-a      Target build location, the final tar.bz2 would be placed here
        -t      PostgreSQL Source tar ball.

Optional:
        -b      Build pgBouncer support, provide pgBouncer source tar ball.
        -o      Build psqlODBC support, provide psqlODBC source tar ball.
	-k	Build pgBackrest support, provide pgBackrest source tar ball.
        -n      Build number, defaults to 1.
        -h      Print Usage/help.

";
}


function checkPostgres {
	echo "# checkPostgres()"
	
	if [[ ! -e $pgTarLocation ]]; then
		echo "File $pgTarLocation not found .... "
		printUsage
		exit 1
	fi	

        cd $baseDir	
	mkdir -p $workDir
	cd $workDir
	mkdir -p logs
	
	tarFileName=`basename $pgTarLocation`
	pgSrcDir=`tar -tf $pgTarLocation | grep HISTORY`
	pgSrcDir=`dirname $pgSrcDir`
	
	tar -xzf $pgTarLocation
		
	isPgConfigure=`$pgSrcDir/configure --version | head -1 | grep "PostgreSQL configure" | wc -l`
	
	if [[ $isPgConfigure -ne 1 ]]; then
		echo "$tarFileName is not a valid postgresql source tarball .... "
		exit 1
	else
		pgSrcV=`$pgSrcDir/configure --version | head -1 | awk '{print $3}'`
		if [[ "${pgSrcV/rc}" =~ ^12.* ]]; then
			pgShortV="12"
			pgLLVM="--with--llvm"
		elif [[ "${pgSrcV/rc}" =~ ^11.* ]]; then
			pgShortV="11"
			pgLLVM="--with--llvm"
		elif [[ "${pgSrcV/rc}" =~ ^10.* ]]; then
			pgShortV="10"
		else
			echo "ERROR: Could not determine Postgres Version for '$pgSrcV'"
			exit 1
		fi
	fi
}


function checkBackrest {
	echo "# checkBackrest()"

	cd $baseDir
	mkdir -p $workDir
	cd $baseDir/$workDir

	backrestSourceDir=`dirname $(tar -tf $backrestTar | grep Makefile.in)`

	tar -xf $backrestTar

	echo "#    srcDir=$backrestSourceDir"

	cd $backrestSourceDir

	return 0
}

function checkBouncer {
	echo "# checkBouncer()"

	cd $baseDir
	mkdir -p $workDir
	cd $baseDir/$workDir
	
	pgBouncerSourceDir=`dirname $(tar -tf $pgBouncerTar | grep AUTHORS)`
	echo "#    srcDir=$pgBouncerSourceDir"
	
	tar -xzf $pgBouncerTar

	cd $pgBouncerSourceDir

	isBouncerConf=`./configure --version | head -1 | grep -i "pgbouncer configure" | wc -l`

	if [[ $isBouncerConf -ne 1 ]]; then
		echo "$pgbouncerTar is not a valid PGBouncer source tarball .... "
		return 1
	else
		pgBouncerSourceVersion=`./configure --version | head -1 | awk '{print $3}'`
	fi
}


function checkODBC {
        echo "# checkOODBC()"
        cd $baseDir
        mkdir -p $workDir

        cd $baseDir/$workDir

        odbcSourceDir=`dirname $(tar -tf $odbcSourceTar | grep "odbcapi.c")`
	echo "#    srcDir=$odbcSourceDir"

        tar -xzf $odbcSourceTar

        cd $odbcSourceDir

        isODBCConfigure=`./configure --version | head -1 | grep "psqlodbc configure" | wc -l`

        if [[ $isODBCConfigure -ne 1 ]]; then
            echo "$odbcSourceTar is not a valid Postgres ODBC source tarball .... "
            return 1
        else
            odbcSourceVersion=`./configure --version | head -1 | awk '{print $3}'`
        fi
}


function buildPostgres {
	echo "# buildPostgres()"	

	cd $baseDir/$workDir/$pgSrcDir
	mkdir -p $baseDir/$workDir/logs
	buildLocation="$baseDir/$workDir/build/pg$pgShortV-$pgSrcV-$pgBldV-linux64"
	echo "#    configure @ $buildLocation"

	conf="./configure --prefix=$buildLocation" 
	conf="$conf --with-openssl --with-ldap --with-libxslt --with-libxml"
	##conf="$conf --with-openssl --with-libxslt --with-libxml"
	conf="$conf --with-uuid=ossp --with-gssapi --with-python --with-perl"
	##conf="$conf --with-uuid=ossp --with-python --with-perl"
	conf="$conf --with-tcl --with-pam"
	
	if [ $pgShortV == "11" ] || [ $pgShortV == "12" ]; then
		configCmnd="$conf --with-llvm"
	else
		configCmnd="$conf"
	fi

	export LD_LIBRARY_PATH=$sharedLibs
	export LDFLAGS="-Wl,-rpath,'$sharedLibs' -L$sharedLibs"
	export CPPFLAGS="-I$includePath"

	log=$baseDir/$workDir/logs/configure.log
	$configCmnd > $log 2>&1
	if [[ $? -ne 0 ]]; then
		echo "# configure failed, check $log"
		exit 1
	fi

	echo "#    make -j 5"
	log=$baseDir/$workDir/logs/make.log
	make -j 5 > $log 2>&1
	if [[ $? -ne 0 ]]; then
		echo "# make failed, check $log"
		exit 1
	fi

	echo "#    make install"
	log=$baseDir/$workDir/logs/make_install.log
	make install > $log 2>&1
	if [[ $? -ne 0 ]]; then
		echo "# make install failed, check $log"
		exit 1
 	fi

	cd $baseDir/$workDir/$pgSrcDir/contrib
	echo "#    make -j 5 contrib"
	make -j5 > $baseDir/$workDir/logs/contrib_make.log 2>&1
	if [[ $? -eq 0 ]]; then
		echo "#    make install contrib"
		make install > $baseDir/$workDir/logs/contrib_install.log 2>&1
		if [[ $? -ne 0 ]]; then
			echo "Failed to install contrib modules ...."
		fi

		if [ -d "bdr" ]; then
			echo "#   building BDR plugin"
			PATH="$PATH:$buildLocation/bin"
			cd bdr
			./autogen.sh
			./configure
			make -j5 -s all
			make -s install
		fi
	fi

	oldPath=$PATH
	PATH="$PATH:$buildLocation/bin"

	cd $baseDir/$workDir/$pgSrcDir/doc
	make > $baseDir/$workDir/logs/docs_make.log 2>&1
	if [[ $? -eq 0 ]]; then
		make install > $baseDir/$workDir/logs/docs_install.log 2>&1
		if [[ $? -ne 0 ]]; then
			echo "Failed to install docs .... "
		fi
	else
		echo "Make failed for docs ...."
		return 1
	fi

	unset LDFLAGS
	unset CPPFLAGS
	unset LD_LIBRARY_PATH
}


function buildBouncer {
	echo "# buildBouncer()"

	srcDir="$baseDir/$workDir/$pgBouncerSourceDir"
	echo "#    srcDir=$srcDir"
        cd $srcDir
	
	./configure --prefix=$buildLocation --disable-rpath --with-libevent=$sharedLibs/../ --with-openssl=$sharedLibs/../ LDFLAGS="-Wl,-rpath,$sharedLibs" > $baseDir/$workDir/logs/pgbouncer_configure.log 2>&1
	
	if [[ $? -ne 0 ]]; then
		echo "PG Bouncer configure failed, check config.log for details ...."
		return 1
	fi

	make > $baseDir/$workDir/logs/pgbouncer_make.log 2>&1
	if [[ $? -ne 0 ]]; then
		echo "PG Bouncer make failed, check logs ...."

		return 1
	fi

	make install > $baseDir/$workDir/logs/pgbouncer_install.log 2>&1
	if [[ $? -ne 0 ]]; then
		echo "Failed to install pgbouncer ...."
		return 1
	fi

	return 0
}


function buildBackrest {
	echo "# buildBackrest()"

        srcDir="$baseDir/$workDir/$backrestSourceDir"
	echo "#    srcDir=$srcDir"
        cd $srcDir
	pwd

	echo "#    configure" 
	log="$baseDir/$workDir/logs/backrest_configure.log"
	./configure --prefix=$buildLocation > $log 2>&1
        if [[ $? -ne 0 ]]; then
                echo "FATAL ERROR: check $log"
		return 1
	fi

	echo "#    make"
	log="$baseDir/$workDir/logs/backrest_make.log"
	make > $log 2>&1
        if [[ $? -ne 0 ]]; then
                echo "FATAL ERROR: check $log"
		return 1
	fi

	echo "#    make install"
	log="$baseDir/$workDir/logs/backrest_install.log"
	make install > $log 2>&1
        if [[ $? -ne 0 ]]; then
                echo "FATAL ERROR: check $log"
		return 1
	fi
}


function buildODBC {
        echo "# buildODBC()"
	
	if [[ ! -e $baseDir/$workDir/$odbcSourceDir ]]; then
		echo "Unable to build ODBC, source directory not found, check logs ...."
		return 1
	fi

        cd $baseDir/$workDir/$odbcSourceDir

	export LD_LIBRARY_PATH=$sharedLibs:$buildLocation/lib
        export OLD_PATH=`echo $PATH`
        export PATH=$sharedBins:$PATH
       
	echo "#    configure" 
	log="$baseDir/$workDir/logs/odbc_configure.log"
        ./configure --prefix=$buildLocation --with-libpq=$buildLocation LDFLAGS="-Wl,-rpath,$sharedLibs -L$sharedLibs" CFLAGS=-I$includePath > $log 2>&1
        if [[ $? -ne 0 ]]; then
                echo "FATAL ERROR: check $log"
		unset LD_LIBRARY_PATH
                return 1
        fi

	echo "#    make"
        log="$baseDir/$workDir/logs/odbc_make.log"
        make > $log 2>&1
        if [[ $? -ne 0 ]]; then
                echo "FATAL ERROR: check $log"
		unset LD_LIBRARY_PATH
                export PATH=$OLD_PATH
                return 1
        fi

	echo "#    make-install"
        make install > $baseDir/$workDir/logs/odbc_install.log 2>&1
        if [[ $? -ne 0 ]]; then
                echo "Failed to install ODBC Driver ...."
		unset LD_LIBRARY_PATH
                export PATH=$OLD_PATH
                return 1
        fi
	
	unset LD_LIBRARY_PATH
        export PATH=$OLD_PATH
	return 0
}


# This function adds the required libs to the build
function copySharedLibs {
	echo "# copySharedLibs()"

	cp $sharedLibs/libreadline.so.6 $buildLocation/lib/
	cp $sharedLibs/libtermcap.so.2 $buildLocation/lib/
	cp $sharedLibs/libz.so.1 $buildLocation/lib/
	cp $sharedLibs/libssl.so.1.0.0 $buildLocation/lib/
	cp $sharedLibs/libcrypto.so.1.0.0 $buildLocation/lib/
	cp $sharedLibs/libk5crypto.so.3 $buildLocation/lib/
	cp $sharedLibs/libkrb5support.so.0 $buildLocation/lib/
	cp $sharedLibs/libgssapi_krb5.so.2 $buildLocation/lib/
	cp $sharedLibs/libk5crypto.so $buildLocation/lib/
	cp $sharedLibs/libkrb5support.so $buildLocation/lib/
	cp $sharedLibs/libkrb5.so.3 $buildLocation/lib/
	cp $sharedLibs/libcom_err.so.3 $buildLocation/lib/
	cp $sharedLibs/libuuid.so.16 $buildLocation/lib/
	cp $sharedLibs/libxslt.so.1 $buildLocation/lib/
	cp $sharedLibs/libuuid.so.16 $buildLocation/lib/
	cp $sharedLibs/libldap-2.4.so.2 $buildLocation/lib/
	cp $sharedLibs/libldap_r-2.4.so.2 $buildLocation/lib/
	cp $sharedLibs/liblber-2.4.so.2 $buildLocation/lib/
	cp $sharedLibs/libsasl2.so.3 $buildLocation/lib/
	cp $sharedLibs/libxml2.so* $buildLocation/lib/
	chmod 755 $buildLocation/lib/libuuid.so.16
	cp $sharedLibs/libevent-2.0.so.5 $buildLocation/lib/
}

function updateSharedLibPaths {
        libPathLog=$baseDir/$workDir/logs/libPath.log
	echo "# updateSharedLibPaths() @ $libPathLog"

	cd $buildLocation/bin
	echo "## looping thru executables"
	for file in `dir -d *` ; do
		##echo "### $file"
		chrpath -r "\${ORIGIN}/../lib" "$file" >> $libPathLog 2>&1
	done

	cd $buildLocation/lib
	echo "## looping thru shared objects"
	for file in `dir -d *so*` ; do
		##echo "### $file"
		chrpath -r "\${ORIGIN}/../lib" "$file" >> $libPathLog 2>&1 
	done

	echo "## looping thru lib/postgresql "
	if [[ -d "$buildLocation/lib/postgresql" ]]; then	
		cd $buildLocation/lib/postgresql
		##echo "### $file"
        	for file in `dir -d *.so` ; do
                	chrpath -r "\${ORIGIN}/../../lib" "$file" >> $libPathLog 2>&1
        	done
	fi
	
}


function scpToPgcServer {
	echo "# scpToPgcServer()"

	pgcServer="192.168.11.139"
	echo "#    pgcServer=$pgcServer"

	destDir=`date +%Y-%m-%d`
	destDir="/home/build/remote/$destDir"
	destSvr="build@$pgcServer"
	destiny="$destSvr:$destDir"
	echo "#    destiny=$destiny"

       	ssh $destSvr "mkdir -p $destDir"
       	scp $tarFile $destiny/

	return

	#bzip2 $pgbinTar
	#if [[ $? -eq 0 ]]; then
	#	mkdir -p $archiveDir/$workDir
	#	mv "$pgbinTar.bz2" $archiveDir/$workDir/
	# 	Below change is for the Nightly build
	#	cp $archiveDir/$workDir/$pgbinTar.bz2 /opt/pginstall/
	#else
	#	echo "Unable to place the archive .... "
	#fi

}


function createBundle {
	echo "# createBundle()"

	bldDir="$baseDir/$workDir/build"
	cd $bldDir
	echo "#    $bldDir"
	Tar="pg$pgShortV-$pgSrcV-$pgBldV-linux$osArch"
	Cmd="tar -cjf $Tar.tar.bz2 $Tar pg$pgShortV-$pgSrcV-$pgBldV-linux$osArch" 
	echo "#    $Cmd"
        $Cmd >> $baseDir/$workDir/logs/tar.log 2>&1
	if [[ $? -ne 0 ]]; then
		echo "Unable to create tar for $buildLocation, check logs .... "
		return
	else
		mkdir -p $archiveDir/$workDir
		mv "$Tar.tar.bz2" $archiveDir/$workDir/

		cd /opt/pgcomponent
		pgCompDir="pg$pgShortV"
        	rm -rf $pgCompDir
		mkdir $pgCompDir 
		tar -xf "$archiveDir/$workDir/$Tar.tar.bz2" --strip-components=1 -C $pgCompDir
	fi
	tarFile="$archiveDir/$workDir/$Tar.tar.bz2"
	echo "#    tarFile=$tarFile"
	return
}

function checkCmd {
	$1
	rc=$?
	if [ "$rc" == "0" ]; then
		return 0
	else
		echo "FATAL ERROR in $1"
		echo ""
		exit 1
	fi
}


function buildApp {
	checkFunc=$1
	buildFunc=$2

	echo "#"	
	$checkFunc
	if [[ $? -eq 0 ]]; then
		$buildFunc
		if [[ $? -ne 0 ]]; then
			echo "FATAL ERROR: in $buildFunc ()"
			exit 1
		fi
	else
		echo "FATAL ERROR: in $checkFunc ()"
		exit 1
	fi
}


function isPassed { 
	if [ "$1" == "0" ]; then
		echo "FATAL ERROR: $2 is required"
		printUsage
		exit 1
	fi
}

###########################################################
#                  MAINLINE                               #
###########################################################

if [[ $# -lt 1 ]]; then
	printUsage
	exit 1
fi

startTime=`date +%Y-%m-%d_%H:%M:%S`
osName=`uname`
echo "#"
echo "### $scriptName for $osName @ $startTime ###"

while getopts "t:a:b:k:o:n:h" opt; do
	case $opt in
		t)
			if [[ $OPTARG = -* ]]; then
       				((OPTIND--))
				continue
      			fi
			pgTarLocation=$OPTARG
			sourceTarPassed=1
			echo "# -t $pgTarLocation"
		;;
		a)
			if [[ $OPTARG = -* ]]; then
				((OPTIND--))
			fi
			archiveDir=$OPTARG
			archiveLocationPassed=1
			echo "# -a $archiveDir"
		;;
		b) 	if [[ $OPTARG = -* ]]; then
				((OPTIND--))
				continue
			fi
			pgBouncerTar=$OPTARG
			buildBouncer=1
			echo "# -b $pgBouncerTar"
		;;
		k) 	if [[ $OPTARG = -* ]]; then
				((OPTIND--))
				continue
			fi
			backrestTar=$OPTARG
			## buildBackrest=1
			## echo "# -k $backrestTar"
			buildBackrest=0
			echo "# -k $backrestTar (IGNORING THIS FOR NOW)"
		;;
		o) 	if [[ OPTARG = -* ]]; then
				((OPTIND--))
				continue
			fi
			buildODBC=1
			odbcSourceTar=$OPTARG
			echo "# -o $odbcSourceTar"
		;;
		n)	
			pgBldV=$OPTARG
			echo "# -n $pgBldV"
		;;
		h)
			printUsage
			exit 0
		;;
		\?)
			printUsage
			echo "Invalid Option Specified, exiting ...." 
			exit 1
		esac
done
echo "###"

isPassed "$archiveLocationPassed" "Target build location (-a)"
isPassed "$sourceTarPassed" "Postgres source tarball (-t)"

echo "#"	
checkCmd "checkPostgres"
checkCmd "buildPostgres"

if [ "$buildBouncer" == "1" ]; then
  buildApp "checkBouncer" "buildBouncer"
fi

if [ "$buildODBC" == "1" ]; then
  buildApp "checkODBC" "buildODBC"
fi

if [ "$buildBackrest" == "1" ]; then
  buildApp "checkBackrest" "buildBackrest"
fi

checkCmd "copySharedLibs"
checkCmd "updateSharedLibPaths"
checkCmd "createBundle"
##checkCmd "scpToPgcServer"

endTime=`date +%Y-%m-%d_%H:%M:%S`
echo "### end at $endTime"
echo "#"

exit 0
