#!/bin/bash
#
# This script generates a relocatable build for PostgreSQL
# The script can additionally build Hadoop FDW, pgbouncer, PostGIS and odbc
# The PostgreSQL build includes all the contrib modules, support for libreadline, libz & openssl
# The script required OpenSSL, Libreadline, termcap, libz etc available under $sharedLibs
# To build PostGIS, the script requires GEOS, GDAL, PROJ and XML2.
#

#set -x
#Define globals
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
pgSourceDir=""
pgSourceVersion=""
pgShortVersion=""
pgBuildVersion=0
pgLLVM=""

pgBouncerSourceDir=""
pgBouncerSourceVer=""

odbcSourceDir=""
odbcSourceVersion=""
odbcSourceTar=""

postgisSourceDir=""
postgisSourceVersion=""
postgisSourceTar=""
postgisBundle=""
orafceSource=""
plJavaSource="/opt/pgbin-build/sources/pljava-1_5_0.tar.gz"
plv8Source="/opt/pgbin-build/sources/plv8-2.0.3.tar.gz"
plrSource="/opt/pgbin-build/sources/plr-REL8_3_0_16.tar.gz"
jsoncSource="/opt/pgbin-build/sources/json-c-0.12-20140410.tar.gz"
psycopgSource="/opt/pgbin-build/sources/psycopg2_2.6_linux64.tar.gz"

geosLib="/opt/gis-tools/geos"
gdalLib="/opt/gis-tools/gdal"
xml2Lib="/opt/gis-tools/libxml2"
projLib="/opt/gis-tools/proj4"

sourceTarPassed=0
archiveLocationPassed=0
buildVersionPassed=0
buildPgBouncer=0
buildSpatial=0
buildODBC=0
buildPlJava=0
buildPLR=0
buildPLV8=0
buildPlProfiler=0
#export PATH=/opt/python27/bin:/opt/perl5184/bin:$PATH


# This function prints the script usage/help
function printUsage {

echo "

Usage:

`basename $0` [OPTIONS]

Required Options:
	-a      Target build location, the final tar.bz2 would be placed here
        -t      PostgreSQL Source tar ball.

Optional:
        -b      Build pgBouncer support, provide pgBouncer source tar ball.
        -n      Build number, defaults to 1.
        -j      JDK path
        -o      Build ODBC support, provide pgsql ODBC source tar ball.
        -h      Print Usage/help.

";

}

# Verify if the provided tar.gz is a valid postgresql tar ball.
function checkSourceTar {
	echo "Verifying PostgreSQL source tarball .... "
	
	if [[ ! -e $pgTarLocation ]]; then
		echo "File $pgTarLocation not found .... "
		printUsage
		exit 1
	fi	
        cd $baseDir	
	mkdir -p $workDir
	cd $workDir
	mkdir -p logs

	#cp $pgTarLocation .
	
        #echo "DEBUG: pgTarLocation = $pgTarLocation"
	tarFileName=`basename $pgTarLocation`
        #echo "DEBUG: tarFileName = $tarFileName"
	pgSourceDir=`tar -tf $pgTarLocation | grep HISTORY`
        #echo "DEBUG: pgSourceDir1 = $pgSourceDir"
	pgSourceDir=`dirname $pgSourceDir`
        #echo "DEBUG: pgSourceDir2 = $pgSourceDir"
	
	#tar -xf $tarFileName
	tar -xzf $pgTarLocation
		
        #echo "DEBUG pgSourceDir = $pgSourceDir"
	isPgConfigure=`$pgSourceDir/configure --version | head -1 | grep "PostgreSQL configure" | wc -l`
	
	if [[ $isPgConfigure -ne 1 ]]; then
		echo "$tarFileName is not a valid postgresql source tarball .... "
		exit 1
	else
		pgSourceVersion=`$pgSourceDir/configure --version | head -1 | awk '{print $3}'`
		if [[ "${pgSourceVersion/rc}" =~ ^12beta* ]]; then
			pgShortVersion="12"
			pgLLVM="--with--llvm"
		elif [[ "${pgSourceVersion/rc}" =~ ^11.* ]]; then
			pgShortVersion="11"
			pgLLVM="--with--llvm"
		elif [[ "${pgSourceVersion/rc}" =~ ^10.* ]]; then
			pgShortVersion="10"
		elif [[ "${pgSourceVersion/rc}" == "$pgSourceVersion" ]]; then
			pgShortVersion="`echo $pgSourceVersion | awk -F '.' '{print $1$2}'`"
		else
			pgShortVersion="`echo $pgSourceVersion | awk -F '.' '{print $1$2}'`"
                	pgShortVersion="`echo ${pgShortVersion:0:2}`"
		fi
		echo "pgShortVersion=$pgShortVersion"
		echo "PostgreSQL $pgSourceVersion source tarball ..... OK"
	fi
	
		
}

# Verify if the tarball provided for pgbouncer is a valid pgbouncer tarball
function checkPGBouncerTar {
	
	cd $baseDir
	mkdir -p $workDir

	cd $baseDir/$workDir
	
	pgBouncerSourceDir=`dirname $(tar -tf $pgBouncerTar | grep AUTHORS)`
	
	tar -xzf $pgBouncerTar

	cd $pgBouncerSourceDir

	isBouncerConfigure=`./configure --version | head -1 | grep "pgbouncer configure" | wc -l`

	if [[ $isBouncerConfigure -ne 1 ]]; then
		echo "$pgbouncerTar is not a valid PGBouncer source tarball .... "
		return 1
	else
		pgBouncerSourceVersion=`./configure --version | head -1 | awk '{print $3}'`
		echo "PGBouncer $pgBouncerSourceVersion source tarball .... OK "
	fi
}

# Verify the ODBC source tar ball
function checkODBCTar {

	echo "Verifying ODBC source tarball .... "
        cd $baseDir
        mkdir -p $workDir

        cd $baseDir/$workDir

        odbcSourceDir=`dirname $(tar -tf $odbcSourceTar | grep "odbcapi.c")`

        tar -xzf $odbcSourceTar

        cd $odbcSourceDir

        isODBCConfigure=`./configure --version | head -1 | grep "psqlodbc configure" | wc -l`

        if [[ $isODBCConfigure -ne 1 ]]; then
                echo "$odbcSourceTar is not a valid Postgres ODBC source tarball .... "
                return 1
        else
                odbcSourceVersion=`./configure --version | head -1 | awk '{print $3}'`
                echo "ODBC $odbcSourceVersion source tarball .... OK "
        fi
	
}


# This function build ore postgresql
# including all the contribs and Hadoop_FDW, if requested.
function buildPostgres {

	echo "Starting PostgreSQL $pgSourceVersion build ...."
	sleep 2
	
	echo "Running PostgreSQL configure .... "	

	cd $baseDir/$workDir/$pgSourceDir
	
	mkdir -p $baseDir/$workDir/logs
	
	if [[ $buildVersionPassed -eq 1 ]]; then
		pgBuildVersion="$pgBuildVersion"
	else
		pgBuildVersion="1"	
	fi

	buildLocation="$baseDir/$workDir/build/pg$pgShortVersion-$pgSourceVersion-$pgBuildVersion-linux64"
	
	if [ $pgShortVersion == "11" ] || [ $pgShortVersion == "12" ]; then
		configCommand="./configure --prefix=$buildLocation --with-openssl --with-ldap --with-libxslt --with-libxml --with-uuid=ossp --with-gssapi --with-python --with-perl --with-tcl --with-llvm"
	else
		configCommand="./configure --prefix=$buildLocation --with-openssl --with-ldap --with-libxslt --with-libxml --with-uuid=ossp --with-gssapi --with-python --with-perl --with-tcl"
	fi
	export LD_LIBRARY_PATH=$sharedLibs
	
	export LDFLAGS="-Wl,-rpath,'$sharedLibs' -L$sharedLibs"
	export CPPFLAGS="-I$includePath"

	echo "Configure command : $configCommand"
	$configCommand > $baseDir/$workDir/logs/configure.log 2>&1

	if [[ $? -ne 0 ]]; then
		echo "Postgresql $pgSourceVersion configure failed, check $baseDir/$workDir/$pgSourceDir/config.log .... "
		exit
	fi

	echo "Configure completed successfuly .... "
	sleep 4
	echo "Running PostgreSQL make .... "
	make > $baseDir/$workDir/logs/make.log 2>&1
	
	if [[ $? -ne 0 ]]; then
		echo "Make failed, check the logs .... "
		exit..
	fi

	echo "Make finished sucessfully .... "
	sleep 2

	echo "Installing PostgreSQL Core build .... "
	make install > $baseDir/$workDir/logs/make_install.log 2>&1
	
      if [[ $? -ne 0 ]]; then
                echo "Build installation failed, check the logs .... "
                exit..
        fi

	echo "Building contrib modules .... "

	cd $baseDir/$workDir/$pgSourceDir/contrib

	make > $baseDir/$workDir/logs/contrib_make.log 2>&1
	if [[ $? -eq 0 ]]; then
		make install > $baseDir/$workDir/logs/contrib_install.log 2>&1
		if [[ $? -ne 0 ]]; then
			echo "Failed to install contrib modules ...."
		fi

               #if [ -d "bdr" ]; then
               #  echo "Building BDR plugin"
               #  PATH="$PATH:$buildLocation/bin"
               #  cd bdr
               #  ./autogen.sh
               #  ./configure
               #  make -j4 -s all
               #  make -s install
               #fi


	#Build orafce if requested.
	oldPath=$PATH
	PATH="$PATH:$buildLocation/bin"
	#echo $PATH

        if [[ $buildPLR -eq 1 ]]; then
                cd $baseDir/$workDir/$pgSourceDir/contrib
                mkdir -p plr && tar -xf $plrSource --strip-components=1 -C plr
		cd plr
                make > $baseDir/$workDir/logs/plr_make.log 2>&1
                if [[ $? -eq 0 ]]; then
                        make install > $baseDir/$workDir/logs/plr_install.log 2>&1
                        if [[ $? -ne 0 ]]; then
                                echo "Failed to install PL/R ..."
                        fi
                else
                        echo "Make failed for PL/R .... "
                fi
        fi

        if [[ $buildPLV8 -eq 1 ]]; then
                cd $baseDir/$workDir/$pgSourceDir/contrib
                mkdir -p plv8 && tar -xf $plv8Source --strip-components=1 -C plv8
		cd plv8
		tar -xf /opt/pgbin-build/sources/v8_build.tar.gz
                make static > $baseDir/$workDir/logs/plv8_make.log 2>&1
                if [[ $? -eq 0 ]]; then
                        make install > $baseDir/$workDir/logs/plv8_install.log 2>&1
                        if [[ $? -ne 0 ]]; then
                                echo "Failed to install PL/V8 ..."
                        fi
                else
                        echo "Make failed for PL/V8 .... "
                fi
		rm -rf build
        fi

        if [[ $buildPlJava -eq 1 ]]; then
                #PATH=/usr/java/jdk1.5.0_22/bin:$PATH
                PATH=/opt/pgbin-build/pgbin/shared/linux_64/maven:$PATH
                cd $baseDir/$workDir/$pgSourceDir/contrib
                mkdir pljava && tar -xf $plJavaSource --strip-components=1 -C pljava
                cd pljava
                mvn clean install > $baseDir/$workDir/logs/pljava_make.log 2>&1
                if [[ $? -eq 0 ]]; then
                        java -jar "pljava-packaging/target/pljava-pg`echo $pgSourceVersion | awk -F '.' '{print $1"."$2}'`-amd64-Linux-gpp.jar" > $baseDir/$workDir/logs/pljava_install.log 2>&1
                        if [[ $? -ne 0 ]]; then
                                echo "Failed to install plJava ..."
                        fi
                fi
			mkdir -p pljava-packaging/target
			cp "/tmp/pljava-pg`echo $pgSourceVersion | awk -F '.' '{print $1"."$2}'`-amd64-Linux-gpp.jar" pljava-packaging/target/
                        java -jar "pljava-packaging/target/pljava-pg`echo $pgSourceVersion | awk -F '.' '{print $1"."$2}'`-amd64-Linux-gpp.jar" > $baseDir/$workDir/logs/pljava_install.log 2>&1
        fi

	#PATH=$oldPath	

	else
		echo "Failed to build conrib modules, check logs .... "
	fi


	#

	cd $baseDir/$workDir/$pgSourceDir/doc
        make > $baseDir/$workDir/logs/docs_make.log 2>&1
        if [[ $? -eq 0 ]]; then
                make install > $baseDir/$workDir/logs/docs_install.log 2>&1
                if [[ $? -ne 0 ]]; then
                        echo "Failed to install docs .... "
                fi
        else
                echo "Make failed for docs ...."
        fi

	echo "PostgreSQL $pgSourceVesion build completed successfully .... "
	unset LDFLAGS
	unset CPPFLAGS
	unset LD_LIBRARY_PATH
}


# This function build pgbouncer and adds to the build
function buildPgBouncer {
	echo "Building pgbouncer .... "
	sleep 5
	cd $baseDir/$workDir/$pgBouncerSourceDir

	
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
	else
		echo "PGBouncer built & installed successfully ...."
	fi
}

# This function builds ODBC driver and adds to the build
function buildODBC {
        echo "Building Postgres ODBC Driver ...."
        sleep 5
	
	if [[ ! -e $baseDir/$workDir/$odbcSourceDir ]]; then
		echo "Unable to build ODBC, source directory not found, check logs ...."
		return 1
	fi

        cd $baseDir/$workDir/$odbcSourceDir

	export LD_LIBRARY_PATH=$sharedLibs:$buildLocation/lib
        export OLD_PATH=`echo $PATH`
        export PATH=$sharedBins:$PATH
        
	#./configure --prefix=$buildLocation --with-libpq=$buildLocation LDFLAGS="-Wl,-rpath,$sharedLibs -L$sharedLibs" CPPFLAGS=-I$includePath > $baseDir/$workDir/logs/odbc_configure.log 2>&1
        #./configure --prefix=$buildLocation --with-libpq=$buildLocation --with-unixodbc=/home/farrukh/pgb_support/unixODBC  LDFLAGS="-Wl,-rpath,$sharedLibs -L$sharedLibs" CPPFLAGS=-I$includePath > $baseDir/$workDir/logs/odbc_configure.log 2>&1
        ./configure --prefix=$buildLocation --with-libpq=$buildLocation LDFLAGS="-Wl,-rpath,$sharedLibs -L$sharedLibs" CFLAGS=-I$includePath > $baseDir/$workDir/logs/odbc_configure.log 2>&1

        if [[ $? -ne 0 ]]; then
                echo "ODBC configure failed, check config.log for details ...."
		unset LD_LIBRARY_PATH
                return 1
        fi

        make > $baseDir/$workDir/logs/odbc_make.log 2>&1
        if [[ $? -ne 0 ]]; then
                echo "ODBC make failed, check logs ...."
		unset LD_LIBRARY_PATH
                export PATH=$OLD_PATH
                return 1
        fi

        make install > $baseDir/$workDir/logs/odbc_install.log 2>&1

        if [[ $? -ne 0 ]]; then
                echo "Failed to install ODBC Driver ...."
		unset LD_LIBRARY_PATH
                export PATH=$OLD_PATH
                return 1
        else
                echo "ODBC Driver built & installed successfully ...."
        fi
	
	unset LD_LIBRARY_PATH
        export PATH=$OLD_PATH
}


# This function builds PostGIS and adds to the build
function buildPostgis {
	echo "Building Postgis ...."
	sleep 5

	if [[ ! -e $baseDir/$workDir/$postgisSourceDir ]]; then
		echo "Unable to build Postgis, source directory not found, check logs .... "
		return 1
	fi

	cd $baseDir/$workDir/$postgisSourceDir

	LD_RUN_PATH=$buildLocation/lib
	export LD_LIBRARY_PATH=$sharedLibs:$buildLocation/lib

	./configure --prefix=$buildLocation --with-pgconfig=$buildLocation/bin/pg_config --with-geosconfig=$geosLib/bin/geos-config --with-projdir=$projLib --with-xml2config=$xml2Lib/bin/xml2-config --with-gdalconfig=$gdalLib/bin/gdal-config LDFLAGS=-Wl,-rpath,'$$ORIGIN'/../lib/ > $baseDir/$workDir/logs/postgis_configure.log 2>&1

        if [[ $? -ne 0 ]]; then
                echo "Postgis configure failed, check config.log for details ...."
                return 1
        fi

	make > $baseDir/$workDir/logs/postgis_make.log 2>&1

        if [[ $? -eq 0 ]]; then
		make install > $baseDir/$workDir/logs/postgis_install.log 2>&1
		if [[ $? -eq 1 ]]; then
			echo "PostGIS install FAILED ..."
		else
			echo "PostGIS build and installed successfully ..." 
		fi	
	else
                echo "Postgis make failed, check logs ...."
                return 1
        fi

	unset LD_LIBRARY_PATH
}

# This function adds the required libs to the build
function copySharedLibs {
	
	echo "Adding shared libs to the new build ...."
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
	cp $sharedLibs/libgss.so* $buildLocation/lib/
	cp $sharedLibs/libuuid.so.16 $buildLocation/lib/
	cp $sharedLibs/libxslt.so.1 $buildLocation/lib/
	cp $sharedLibs/libuuid.so.16 $buildLocation/lib/
	if [[ $pgShortVersion == "12" || $pgShortVersion == "11" || $pgShortVersion == "10" ]]; then
		cp $sharedLibs/libldap-2.4.so.2 $buildLocation/lib/
		cp $sharedLibs/libldap_r-2.4.so.2 $buildLocation/lib/
		cp $sharedLibs/liblber-2.4.so.2 $buildLocation/lib/
		cp $sharedLibs/libsasl2.so.3 $buildLocation/lib/
	fi
	cp $xml2Lib/lib/libxml2.so* $buildLocation/lib/
	chmod 755 $buildLocation/lib/libuuid.so.16

        #if [[ $buildHadoopFDW -eq 1 ]]; then
        #        cp $sharedLibs/libthrift-0.9.1.so $buildLocation/lib/
#		cp $sharedLibs/libfb303.a $buildLocation/lib/
  #      fi

        if [[ $buildCassandraFDW -eq 1 ]]; then
                cp $sharedLibs/libcassandra.so.2 $buildLocation/lib/
               cp $sharedLibs/libuv.so.1 $buildLocation/lib/
        fi

	if [[ $buildPgBouncer -eq 1 ]]; then
		cp $sharedLibs/libevent-2.0.so.5 $buildLocation/lib/
	fi

	if [[ $buildSpatial -eq 1 ]]; then
		cp $projLib/lib/libproj.so.9 $buildLocation/lib/
		cp $geosLib/lib/libgeos_c.so.1 $buildLocation/lib/
		cp $geosLib/lib/libgeos-3.5.0.so $buildLocation/lib/
		cp $gdalLib/lib/libgdal.so.1 $buildLocation/lib/
		cp $xml2Lib/lib/libxml2.so* $buildLocation/lib/
		
	fi
}

# This function updates the library linking paths for libs and binaries
function updateSharedLibPaths {
	cd $buildLocation/bin

	for file in `dir -d *` ; do
		chrpath -r "\${ORIGIN}/../lib" "$file" >> $baseDir/$workDir/logs/libPath.log 2>&1
	done

	cd $buildLocation/lib
	
	for file in `dir -d *so*` ; do
		chrpath -r "\${ORIGIN}/../lib" "$file" >> $baseDir/$workDir/logs/libPath.log 2>&1 
	done

	if [[ -d "$buildLocation/lib/postgresql" ]]; then	
		cd $buildLocation/lib/postgresql

        	for file in `dir -d *.so` ; do
                	chrpath -r "\${ORIGIN}/../../lib" "$file" >> $baseDir/$workDir/logs/libPath.log 2>&1
        	done
	fi
	
}

#Add pgHA to the newly created pgbin build
function bundlePgHA {

	echo "Adding pgHA to the pgbin build ...."	
	cd $baseDir/$workDir
	tar -xzf $pgHASourceTar 
	
	pghaSD=`tar -tf $pgHASourceTar | grep COPYRIGHT | head -1`

        pghaSourceDir=`dirname "$pghaSD"`
	
	mkdir -p $buildLocation/pgha

	cp -r $baseDir/$workDir/$pghaSourceDir/bin $buildLocation/pgha/
	cp -r $baseDir/$workDir/$pghaSourceDir/cfg $buildLocation/pgha/
	cp -r $baseDir/$workDir/$pghaSourceDir/doc $buildLocation/pgha/
	cp -r $baseDir/$workDir/$pghaSourceDir/COPYRIGHT $buildLocation/pgha/
	cp -r $baseDir/$workDir/$pghaSourceDir/support/pgBouncer/cfg/* $buildLocation/pgha/cfg/

	if [[ $? -eq 0 ]]; then
		return 0
	else
		return 1
	fi

}


# Creates the final bundle
function createPgbinBundle {
	cd $baseDir/$workDir/build
	pgbinTar="pg$pgShortVersion-$pgSourceVersion-$pgBuildVersion-linux$osArch"
	tar -cjf "$pgbinTar.tar.bz2" "pg$pgShortVersion-$pgSourceVersion-$pgBuildVersion-linux$osArch" >> $baseDir/$workDir/logs/tar.log 2>&1
	
	if [[ $? -ne 0 ]]; then
		echo "Unable to create tar for $buildLocation, check logs .... "
	else
		mkdir -p $archiveDir/$workDir
		mv "$pgbinTar.tar.bz2" $archiveDir/$workDir/
		echo "PostgreSQL $pgSourceVersion packaged ...."

		cd /opt/pgcomponent
		pgCompDir="pg$pgShortVersion"
        	rm -rf $pgCompDir
		mkdir $pgCompDir && tar -xf "$archiveDir/$workDir/$pgbinTar.tar.bz2" --strip-components=1 -C $pgCompDir
		
		destDir=`date +%Y-%m-%d`
        	#ssh build@10.0.1.151 "mkdir -p /opt/pgbin-builds/$destDir"
        	#scp "$archiveDir/$workDir/$pgbinTar.tar.bz2" build@10.0.1.151:/opt/pgbin-builds/$destDir/
		#bzip2 $pgbinTar
		#if [[ $? -eq 0 ]]; then
		#	mkdir -p $archiveDir/$workDir
	#		mv "$pgbinTar.bz2" $archiveDir/$workDir/
			# Below change is for the Nightly build
			#cp $archiveDir/$workDir/$pgbinTar.bz2 /opt/pginstall/
	#	else
	#		echo "Unable to place the archive .... "
	#	fi
	fi
}

if [[ $# -lt 1 ]]; then
	printUsage
	exit 1
fi

	while getopts "t:a:s:b:n:d:f:o:g:q:c:j:l:y:m:r:u:i:p:vh" opt; do
		case $opt in
			t)
				if [[ $OPTARG = -* ]]; then
        				((OPTIND--))
        				continue
      				fi
					pgTarLocation=$OPTARG
					sourceTarPassed=1
			;;
			a)
				if [[ $OPTARG = -* ]]; then
					((OPTIND--))
				fi
				archiveDir=$OPTARG
				archiveLocationPassed=1
			;;
			s)
                                if [[ $OPTARG = -* ]]; then
                                        ((OPTIND--))
                                        continue
                                fi

				postgisSourceTar=$OPTARG
				buildSpatial=1
			;;
			b)
				if [[ $OPTARG = -* ]]; then
					((OPTIND--))
					continue
				fi
				
				pgBouncerTar=$OPTARG
				buildPgBouncer=1
			;;
			n)
				if [[ $OPTARG = -* ]]; then
					((OPTIND--))
					continue
				fi
				pgBuildVersion=$OPTARG
				#echo "DEBUG: pgBuildVersion=$pgBuildVersion"
				buildVersionPassed=1
			;;
			d)
				if [[ $OPTARG = -* ]]; then
					((OPTIND--))
					continue
				fi
				buildHadoopFDW=1
				hadoopSourceTar=$OPTARG
			;;
			c)
				if [[ $OPTARG = -* ]]; then
					((OPTIND--))
					continue
				fi
				buildCassandraFDW=1
				cassandraSourceTar=$OPTARG
			;;
			j)
				if [[ $OPTARG = -* ]]; then
					((OPTIND--))
					continue
				fi
				jdkPath=$OPTARG
			;;
			o)
				if [[ OPTARG = -* ]]; then
					((OPTIND--))
					continue
				fi
				buildODBC=1
				odbcSourceTar=$OPTARG
			;;
			g)
				if [[ OPTIND = -* ]]; then
					((OPTIND--))
					continue
				fi
				addpgHA=1
				pgHASourceTar=$OPTARG
			;;
                        q)
                                if [[ $OPTARG = -* ]]; then
                                        ((OPTIND--))
                                        continue
                                fi
                                buildPgTSQL=1
                                pgTSQLSourceTar=$OPTARG
                        ;;
			l)
				if [[ $OPTARG = -* ]]; then
					((OPTIND--))
					continue
				fi
				buildOracleFDW=1
				oracleFDWSource=$OPTARG
			;;
			y)
				if [[ $OPTARG = -* ]]; then
					((OPTIND--))
					continue
				fi
				buildTDS_FDW=1
				tdsFDWSource=$OPTARG
			;;
			m)
				if [[ $OPTARG = -* ]]; then
					((OPTIND--))
					continue
				fi
				buildMongoFDW=1
				mongoFDWSource=$OPTARG
			;;
			r)
				if [[ $OPTARG = -* ]]; then
					((OPTIND--))
					continue
				fi
				buildMysqlFDW=1
				mysqlFDWSource=$OPTARG
			;;
			f)
				if [[ $OPTARG = -* ]]; then
					((OPTIND--))
					continue
				fi
				buildOrafce=1
				orafceSource=$OPTARG
			;;
			u)
				if [[ $OPTARG = -* ]]; then
					((OPTIND--))
					continue
				fi
				buildPGAudit=1
				pgAuditSource=$OPTARG
			;;
			i)
				if [[ $OPTARG = -* ]]; then
					((OPTIND--))
					continue
				fi
				buildSetUser=1
				setUserSource=$OPTARG
			;;
			p)
                                if [[ $OPTARG = -* ]]; then
                                        ((OPTIND--))
                                        continue
                                fi
                                buildPlProfiler=1
                                plProfilerSource=$OPTARG
			;;
			h)
				printUsage
			;;
			v)
				printRevisionInfo
			;;
			\?)
				printUsage
				echo "Invalid Option Specified, exiting ...." 
				exit 1
		esac
	done



if [[ $archiveLocationPassed -eq 0 ]]; then
	echo " "
	echo "Archive location required, this is where the final tar.bz2 would be placed"
	printUsage
	exit 1
fi

if [[ $sourceTarPassed -eq 0 ]]; then
	echo "PostgreSQL Source tarball is required for the build ....."
	echo " "	
	printUsage
	exit 1
else
	
	checkSourceTar
	buildPostgres
	
	if [[ $buildPgBouncer -eq 1 ]]; then
		checkPGBouncerTar
		if [[ $? -eq 0 ]]; then
			buildPgBouncer
		else
			echo "Can't build PGBouncer ...."
		fi
	fi

        if [[ $buildODBC -eq 1 ]]; then
                checkODBCTar
                if [[ $? -eq 0 ]]; then
                        buildODBC
                else
                        echo "Can't build ODBC Driver, check logs ...."
                fi
        fi

	if [[ $buildSpatial -eq 1 ]]; then 
		checkPostgisTar
		if [[ $? -eq 0 ]]; then
			buildPostgis
		else
			echo "Can't build Postgis"
		fi
	fi 

	if [[ $addpgHA -eq 1 ]]; then
		bundlePgHA
		if [[ $? -ne 0 ]]; then
			echo "Failed to add pgHA to pgBin package ...."
		fi		
	fi
	
	#checkHadoopTar

	copySharedLibs
	updateSharedLibPaths

	createPgbinBundle
fi


