#!/bin/bash
#
# This script generates a relocatable OSX_64 build for PostgreSQL
# The script can additionally build Hadoop FDW, pgbouncer, PostGIS and odbc
# The PostgreSQL build includes all the contrib modules, support for libreadline, libz & openssl
# The script required OpenSSL, Libreadline, termcap, libz etc available under $sharedLibs
# To build PostGIS, the script requires GEOS, GDAL, PROJ and XML2.
#
# Author: Farrukh Afzal (farrukha@openscg.com)
# 
# Revision History
# ===========================================================================
# Date        |  Author       |    Description                                            
# ===========================================================================
# 2013-05-25  | Farrukh       |    Initial Implementation
# 2013-05-27  | Farrukh       |    Added support to verify the source tarballs before starting the build
# 2013-05-28  | Farrukh       |    Added support for building Hadoop FDW and pgbouncer
# 2013-05-28  | Farrukh       |    Added support for odbc driver
# 2013-05-29  | Farrukh       |    Added support for PostGIS
# 2013-06-17  | Farrukh       |    Added dynamic lib & include paths
# 2013-06-20  | Farrukh       |    Added support to add pgHA to the build from pgHA tar.gz
# 2013-06-25  | Farrukh       |    Created a sperate script for OSX version and added required libs
# 2013-12-19  | Haroon        |    Added support for building pgTSQL
# 2015-10-12  | Farrukh       |    Added support for building Orafce
# 2016-02-08  | Farrukh       |    Fixed broken command line arguments.
# 2016-03-04  | Farrukh       |    Added support for OracleFDw for OSX.
# 2016-04-13  | Farrukh       |    Added pgAdudit extension, provide source tarball.
# 2016-04-13  | Farrukh       |    Added SetUser extension, provide source tarball.
# 
#
#============================================================================
#

#Define globals
archiveDir="/opt/builds/"
baseDir="`pwd`/.."
workDir=`date +%Y%m%d_%H%M`
buildLocation=""

sharedLibs="$baseDir/shared/osx_64/lib"
includePath="$baseDir/shared/osx_64/include"
export ORACLE_HOME="/opt/pgbin-build/pgbin/shared/instantclient_10_2"
plJavaSource="/opt/pgbin-build/sources/pljava-1_5_0.tar.gz"
plProfilerSource=""

pgTarLocation=""
pgSourceDir=""
pgSourceVersion=""
pgShortVersion=""
pgBuildVersion=0

pgBouncerSourceDir=""
pgBouncerSourceVer=""

odbcSourceDir=""
odbcSourceVersion=""
odbcSourceTar=""

postgisSourceDir=""
postgisSourceVersion=""
postgisBundle=""
postgisSourceTar=""
#orafceSource="/opt/pgbin-build/sources/orafce-VERSION_3_2_1.tar.gz"
orafceSource=""
setUserSource=""
pgAuditSource=""
pgAuditSource=""
plv8Source="/opt/pgbin-build/sources/plv8-2.0.3.tar.gz"
plv8Dependencies="/opt/pgbin-build/sources/v8_153_depenedencies.tar.gz"
psycopgSource="/opt/pgbin-build/sources/psycopg2_2.6_ox64.tar.gz"

geosLib="/opt/gis-tools/geos350"
gdalLib="/opt/gis-tools/gdal"
xml2Lib="/opt/gis-tools/libxml2"
projLib="/opt/gis-tools/proj4"

sourceTarPassed=0
archiveLocationPassed=0
buildVersionPassed=0
buildPgBouncer=0
buildSpatial=0
buildHadoopFDW=0
#buildHiveFDW=0
buildODBC=0
buildPgTSQL=0
buildCassandraFDW=0
buildOrafce=0
buildPlJava=0
buildPGAudit=0
buildSetUser=0
buildPlProfiler=0
buildPLV8=0

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
        -c      Build Cassandra FDW, Provide Cassandra FDW source tar ball.
        -d      Build Hadoop FDW, provide hadoop source tar ball (tar.gz)
	-g	Add pgHA to the build, provide pgHA source.
        -n      Build number, defaults to 1.
        -j      JDK path
        -o      Build ODBC support, provide pgsql ODBC source tar ball.
        -q      Build pgTSQL, Provide pgTSQL source tar ball.
        -s      Build spatial(PostGIS), provide PostGIS source tar ball.
	-f      Build Orafce, provide Orafce source tar ball.
	-l      Build Oracle FDW, provide Oracle FDW source tar ball.
	-u      Build SetUser Extension, provide source tar ball.
	-i      Build pgAudit extension, provide source tar ball.
	-p      Build plProfiler, provide source tar ball.
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
	
	tarFileName=`basename $pgTarLocation`
	pgSourceDir=`tar -tf $pgTarLocation | grep INSTALL`
	pgSourceDir=`dirname $pgSourceDir`
	
	#tar -xf $tarFileName
	tar -xzf $pgTarLocation
		
	isPgConfigure=`$pgSourceDir/configure --version | head -1 | grep "PostgreSQL configure" | wc -l`
	
	if [[ $isPgConfigure -ne 1 ]]; then
		echo "$tarFileName is not a valid postgresql source tarball .... "
		exit 1
	else
		pgSourceVersion=`$pgSourceDir/configure --version | head -1 | awk '{print $3}'`
		if [[ "${pgSourceVersion/rc}" =~ 11.* ]]; then
                        pgShortVersion="11"
		elif [[ "${pgSourceVersion/rc}" == 10* ]]; then
                        pgShortVersion="10"
		elif [[ "${pgSourceVersion/rc}" == "$pgSourceVersion" ]]; then
                        pgShortVersion=`echo $pgSourceVersion | awk -F '.' '{print $1$2}'`
                else   
                        pgShortVersion="`echo $pgSourceVersion | awk -F '.' '{print $1$2}'`"
                        pgShortVersion="`echo ${pgShortVersion:0:2}`"
                fi
		echo "PostgreSQL $pgSourceVersion source tarball ..... OK"
		echo "pgShortVersion is : $pgShortVersion"
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

# Verify if the Postgis tarball is valid
function checkPostgisTar {
	echo "Verifying PostGIS source tarball .... "

	cd $baseDir
	mkdir -p $workDir
	cd $baseDir/$workDir

	postgisSourceDir=`dirname $(tar -tf $postgisSourceTar | grep "README.postgis")`
	
	tar -xzf $postgisSourceTar

	cd $postgisSourceDir

	isPostgisConfigure=`./configure --help | grep "geos" | wc -l`

	if [[ $isPostgisConfigure -ne 1 ]]; then
		echo "$postgisSourceTar is not a valid Postgis source tarball .... "
		return 1
	else
		postgisSourceVersion=`more Version.config | grep MAJOR | awk 'BEGIN {FS = "=" } ; {print $2}'`
		postgisSourceVersion="$postgisSourceVersion."`more Version.config | grep MINOR | awk 'BEGIN {FS = "=" } ; {print $2}'`
		postgisSourceVersion="$postgisSourceVersion."`more Version.config | grep MICRO | awk 'BEGIN {FS = "=" } ; {print $2}'`
		echo "Postgis $postgisSourceVersion source tarball .... OK "
	fi
}

# This function builds core postgresql
# including all the contribs, and FDW extensions if requested.
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

	
	buildLocation="$baseDir/$workDir/build/pg$pgShortVersion-$pgSourceVersion-$pgBuildVersion-osx64"

	echo "Build Location : $buildLocation"

	if [[ $pgShortVersion -ge 94 || $pgShortVersion -eq 10 || $pgShortVersion -eq 11 ]]; then
		configCommand="./configure --prefix=$buildLocation --disable-rpath --enable-thread-safety --with-openssl --with-libxml --with-libxslt --with-perl --with-python --with-tcl --with-uuid=e2fs"
	else
		configCommand="./configure --prefix=$buildLocation --disable-rpath --enable-thread-safety --with-openssl --with-libxml --with-libxslt --with-perl --with-python --with-tcl"
	fi

	echo "Configure Command : $configCommand"

	export LD_LIBRARY_PATH=$sharedLibs
	
	export LDFLAGS="-O2 -Wl,-rpath,'$sharedLibs' -L$sharedLibs"
	export CPPFLAGS="-I$includePath"
	#export CFLAGS="-ggdb"

	#DEBUG echo "Configure command : $configCommand"
	$configCommand > $baseDir/$workDir/logs/configure.log 2>&1

	if [[ $? -ne 0 ]]; then
		echo "Postgresql $pgSourceVersion configure failed, check $baseDir/$workDir/$pgSourceDir/config.log .... "
		exit
	fi

	echo "Configure completed successfuly .... "
	sleep 4
	echo " Running PostgreSQL make .... "
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

#		if [[ $phShortVersion != "96" ]]; then
#			echo "Building PL/Debugger ...."
#			tar -xf /opt/pgbin-build/sources/pldebugger.tar.gz
#			cd pldebugger
#			make > $baseDir/$workDir/logs/pldebugger_make.log 2>&1
#			make install > $baseDir/$workDir/logs/pldebugger_install.log 2>&1
#		fi

	else
		echo "Failed to build conrib modules, check logs .... "
	fi
	
	oldPath=$PATH
	export PATH=$buildLocation/bin:$PATH
	if [[ $buildOrafce -eq 1 ]]; then
		cd $baseDir/$workDir/$pgSourceDir/contrib
		mkdir orafce && tar -xf $orafceSource --strip-components=1 -C orafce
		cd orafce
		make > $baseDir/$workDir/logs/orafce_make.log 2>&1
		if [[ $? -eq 0 ]]; then
			make install > $baseDir/$workDir/logs/orafce_install.log 2>&1
			if [[ $? -eq 0 ]]; then
				echo "Orafce installed successfully ... "
			else
				echo "Failed to installed orafce ..."
			fi
		else
			echo "Orafce make failed ..."
		fi
	fi
	#PATH=$oldPath

	#Build plJava
        if [[ $buildPlJava -eq 1 ]]; then
                #PATH=/usr/java/jdk1.5.0_22/bin:$PATH
                PATH=/opt/pgbin-build/pgbin/shared/osx_64/maven/bin:$PATH
                cd $baseDir/$workDir/$pgSourceDir/contrib
                mkdir pljava && tar -xf $plJavaSource --strip-components=1 -C pljava
                cd pljava
                mvn clean install > $baseDir/$workDir/logs/pljava_make.log 2>&1
                if [[ $? -eq 0 ]]; then
                        java -jar "pljava-packaging/target/pljava-pg`echo $pgSourceVersion | awk -F '.' '{print $1"."$2}'`-x86_64-MacOSX-gpp.jar" > $baseDir/$workDir/logs/pljava_install.log 2>&1
                        if [[ $? -ne 0 ]]; then
                                echo "Failed to install plJava ..."
                        fi
                fi
        fi


	#Build Hadoop FDW
        if [[ $buildHadoopFDW -eq 1 ]]; then
                cd $baseDir/$workDir/$pgSourceDir/contrib
                mkdir hadoop_fdw && tar -xf $hadoopSourceTar --strip-components=1 -C hadoop_fdw
                cd hadoop_fdw
                USE_PGXS=1 make clean > $baseDir/$workDir/logs/hadoopFDW_make.log 2>&1
                if [[ $? -eq 0 ]]; then
                        USE_PGXS=1 make install > $baseDir/$workDir/logs/hadoopFDW_install.log 2>&1
                        if [[ $? -ne 0 ]]; then
                                echo "HadoopFDW installed failed .... FAILED"
                        fi
                fi
		cd $buildLocation/lib/postgresql
		jar cvf Hadoop_FDW.jar Hadoop*.class > $baseDir/$workDir/logs/hadoopFDW_jar.log
		rm -rf *.class
        fi

        # building cassacdra fdw
        if [[ $buildCassandraFDW -eq 1 ]]; then
                cd $baseDir/$workDir/$pgSourceDir/contrib
                mkdir cassandra2c_fdw && tar -xf $cassandraSourceTar --strip-components=1 -C cassandra2c_fdw
                cd cassandra2c_fdw
                USE_PGXS=1 make > $baseDir/$workDir/logs/cassandrafdw_make.log 2>&1 
                if [[ $? -eq 0 ]]; then
                   make install > $baseDir/$workDir/logs/cassandrafdw_makeinstall.log 2>&1
                   if [[ $? -ne 0 ]]; then
                      echo -e "Cassandra FDW make installation failed ...."
		   else
		      echo "CassandraFDW installed successfully ...."
                   fi
                else
                	echo "CassandraFDW make failed. Please check the logs .... "
                fi
        fi

        if [[ $buildOracleFDW -eq 1 ]]; then
                cd $baseDir/$workDir/$pgSourceDir/contrib
                mkdir oracle_fdw && tar -xf $oracleFDWSourceTar --strip-components=1 -C oracle_fdw
                cd oracle_fdw
                USE_PGXS=1 make > $baseDir/$workDir/logs/oraclefdw_make.log 2>&1
                if [[ $? -eq 0 ]]; then
                   make install > $baseDir/$workDir/logs/oraclefdw_makeinstall.log 2>&1
                   if [[ $? -ne 0 ]]; then
                      echo "Oracle FDW make installation failed ...."
                   else
		     echo "Oracle FDW installed successfully ...."
		   fi
                else   
                        echo "Oracle FDW make failed. Please check the logs .... "
                fi
        fi


        # building pgTSQL
        if [[ $buildPgTSQL -eq 1 ]]; then
                cp $pgTSQLSourceTar $baseDir/$workDir/$pgSourceDir/contrib
                pgTSQLSourceDir=`dirname $(tar -tf $pgTSQLSourceTar | grep pgtsql.control)`
                cd $baseDir/$workDir/$pgSourceDir/contrib
                tar -xzf $pgTSQLSourceTar
                cd $pgTSQLSourceDir
                #export PATH="$PATH:$baseDir/$workDir/build/pgbin-$pgSourceVersion/bin"
                make > $baseDir/$workDir/logs/pgTSQL_make.log 2>&1
                if [[ $? -eq 0 ]]; then
                    echo -e "Running pgTSQL make install ...."
                    make install > $baseDir/$workDir/logs/pgTSQL_makeinstall.log 2>&1
                    if [[ $? -eq 0 ]]; then
                        echo -e "pgTSQL make install successful ...."
                    else
                        echo -e "pgTSQL make install failed ...."
                    fi
                else
                    echo "pgTSQL make failed. Please check the logs ...."
                fi
        fi

        if [[ $buildPGAudit -eq 1 ]]; then
                cd $baseDir/$workDir/$pgSourceDir/contrib
                mkdir -p pgaudit && tar -xf $pgAuditSource --strip-components=1 -C pgaudit
                cd pgaudit
                make > $baseDir/$workDir/logs/pgaudit_make.log 2>&1
                if [[ $? -eq 0 ]]; then
                        make install > $baseDir/$workDir/logs/pgaudit_install.log 2>&1
                        if [[ $? -ne 0 ]]; then
                                echo "PGAudit install Failed .... "
                        fi
                else
                        echo "PGAudit Make Failed .... "
                fi

        fi

        if [[ $buildSetUser -eq 1 ]]; then
                cd $baseDir/$workDir/$pgSourceDir/contrib
                mkdir -p setuser && tar -xf $setUserSource --strip-components=1 -C setuser
                cd setuser
                make > $baseDir/$workDir/logs/setuser_make.log 2>&1
                if [[ $? -eq 0 ]]; then
                        make install > $baseDir/$workDir/logs/setuser_install.log 2>&1
                        if [[ $? -ne 0 ]]; then
                                echo "Set-User install Failed .... "
                        fi
                else
                        echo "Set-User Make Failed .... "
                fi
        fi

        if [[ $buildPlProfiler -eq 1 ]]; then
                cd $baseDir/$workDir/$pgSourceDir/contrib
	        mkdir plprofiler && tar -xf $plProfilerSource --strip-components=1 -C plprofiler
        	cd plprofiler

	        USE_PGXS=1 make > $baseDir/$workDir/logs/plprofiler_make.log 2>&1
        	if [[ $? -eq 0 ]]; then
                	USE_PGXS=1 make install > $baseDir/$workDir/logs/plprofiler_install.log 2>&1
                	if [[ $? -ne 0 ]]; then
                       	      echo "Failed to install PlProfiler ..."
                	fi
        		mkdir -p $buildLocation/python/site-packages
        		cd python-plprofiler
                        cp -R plprofiler $buildLocation/python/site-packages
                        cp plprofiler-bin.py $buildLocation/bin/plprofiler
                        cd $buildLocation/python/site-packages
                        tar -xf $psycopgSource
        	else
                	echo "Make failed for PlProfiler .... "
        	fi
        	rm -rf build
        fi


        if [[ $buildPLV8 -eq 1 ]]; then
                cd $baseDir/$workDir/$pgSourceDir/contrib
                mkdir -p plv8 && tar -xf $plv8Source --strip-components=1 -C plv8
                cd plv8
		tar -xf $plv8Dependencies
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


        #
	#echo "Installing the build .... "

	echo "Building HTML docs ...."
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
	
	PATH=$oldPath
	#make install
	
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

	
	./configure --prefix=$buildLocation --with-libevent=$sharedLibs/../ --with-openssl=$sharedLibs/../ LDFLAGS="-Wl,-rpath,$sharedLibs" > $baseDir/$workDir/logs/pgbouncer_configure.log 2>&1
	
	if [[ $? -ne 0 ]]; then
		echo "PG Bouncer configure failed, check config.log for details ...."
		return 1
	fi

	make > $baseDir/$workDir/logs/pgbouncer_make.log 2>&1
	if [[ $? -ne 0 ]]; then
		echo "PG Bouncer make failed, check logs ...."

		return 1
	fi

	cp pgbouncer $buildLocation/bin/	
#	make install > $baseDir/$workDir/logs/pgbouncer_install.log 2>&1

	if [[ $? -ne 0 ]]; then
		echo "Failed to install pgbouncer ....."
		return 1
	else
		echo "PGBouncer built & installed successfully ...."
	fi
}

# This function builds ODBC driver and adds to the build
function buildODBC {
        echo "Building Postgres ODBC Driver .... "
        sleep 5
	
	if [[ ! -e $baseDir/$workDir/$odbcSourceDir ]]; then
		echo "Unable to build ODBC, source directory not found, check logs .... "
		return 1
	fi

        cd $baseDir/$workDir/$odbcSourceDir


        ./configure --prefix=$buildLocation --with-libpq=$buildLocation/lib/ LDFLAGS='-Wl,-rpath,$sharedLibs' > $baseDir/$workDir/logs/odbc_configure.log 2>&1

        if [[ $? -ne 0 ]]; then
                echo "ODBC configure failed, check config.log for details ...."
                return 1
        fi

        make > $baseDir/$workDir/logs/odbc_make.log 2>&1
        if [[ $? -ne 0 ]]; then
                echo "ODBC make failed, check logs ...."

                return 1
        fi

        make install > $baseDir/$workDir/logs/odbc_install.log 2>&1

        if [[ $? -ne 0 ]]; then
                echo "Failed to install ODBC Driver ...."
                return 1
        else
                echo "ODBC Driver built & installed successfully ...."
        fi
}


# This function builds PostGIS and adds to the build
function buildPostgis {
	echo "Building Postgis .... "
	sleep 5

	if [[ ! -e $baseDir/$workDir/$postgisSourceDir ]]; then
		echo "Unable to build Postgis, source directory not found, check logs .... "
		return 1
	fi

	cd $baseDir/$workDir/$postgisSourceDir

	#FIX xml2config issue later# ./configure --prefix=$buildLocation --with-pgconfig=$buildLocation/bin/pg_config --with-geosconfig=$geosLib/bin/geos-config --with-projdir=$projLib --with-xml2config=$xml2Lib/bin/xml2-config --with-gdalconfig=$gdalLib/bin/gdal-config LDFLAGS=-Wl,-rpath,'$$ORIGIN'/../lib/ > $baseDir/$workDir/logs/postgis_configure.log 2>&1
	./configure --prefix=$buildLocation --with-pgconfig=$buildLocation/bin/pg_config --with-geosconfig=$geosLib/bin/geos-config --with-projdir=$projLib --with-gdalconfig=$gdalLib/bin/gdal-config LDFLAGS=-Wl,-rpath,'$$ORIGIN'/../lib/ > $baseDir/$workDir/logs/postgis_configure.log 2>&1

        if [[ $? -ne 0 ]]; then
                echo "Postgis configure failed, check config.log for details ...."
                return 1
        fi

	make > $baseDir/$workDir/logs/postgis_make.log 2>&1

        if [[ $? -ne 0 ]]; then
                echo "Postgis make failed, check logs ...."

                return 1
        fi
	
	#make install >  $baseDir/$workDir/logs/postgis_install.log 2>&1

	postgisBundle="postgis`echo $postgisSourceVersion | awk -F '.' '{print $1$2}'`-${postgisSourceVersion}-pg`echo $pgSourceVersion | awk -F      '.' '{print $1$2}'`-linux64"
        mv $buildLocation "${buildLocation}_master"
        mkdir -p "$buildLocation/lib/postgresql/pgxs"
        mkdir -p "$buildLocation/bin"
        cp "${buildLocation}_master/bin/pg_config" "${buildLocation}/bin"
        cp -r "${buildLocation}_master/lib/postgresql/pgxs" "${buildLocation}/lib/postgresql/"
        #cp "${buildLocation}_master/lib/postgresql/pgxs/src/Makefile.global" "${buildLocation}/lib/postgresql/pgxs/src/"
        #cp "${buildLocation}_master/lib/postgresql/pgxs/src/Makefile.port" "${buildLocation}/lib/postgresql/pgxs/src/"
        #cp "${buildLocation}_master/lib/postgresql/pgxs/src/Makefile.shlib" "${buildLocation}/lib/postgresql/pgxs/src/"
        make install >  $baseDir/$workDir/logs/postgis_install.log 2>&1
        mv $buildLocation "$baseDir/$workDir/build/$postgisBundle"
        mv "${buildLocation}_master" $buildLocation

	if [[ $? -ne 0 ]]; then
        	checkError=`more $baseDir/$workDir/logs/postgis_install.log | grep "Segmentation fault" |wc -l`
        	if [[ $checkError -eq 1 ]]; then
                	while [ $checkError -ne 0 ]; do
                        	make install > $baseDir/$workDir/logs/postgis_install.log 2>&1
				if [[ $? -eq 0 ]]; then
					echo "Postgis built & installed successfully ...."
					return 0
				fi
                        	checkError=`more $baseDir/$workDir/logs/postgis_install.log | grep "Segmentation fault" |wc -l`
                	done
        	fi
	else
        	echo "Postgis Installed Successfully .... "
	fi


}

# This function adds the required libs to the build
function copySharedLibs {
	
	echo "Adding shared libs to the new build ...."
	#cp $sharedLibs/libreadline.so.6 $buildLocation/lib/
	#cp $sharedLibs/libtermcap.so.2 $buildLocation/lib/
	#cp $sharedLibs/libz.so.1 $buildLocation/lib/
	#cp $sharedLibs/libssl.so.1.0.0 $buildLocation/lib/
	#cp $sharedLibs/libcrypto.so.1.0.0 $buildLocation/lib/

	cp $sharedLibs/libssl.1.0.0.dylib $buildLocation/lib/   
        cp $sharedLibs/libcrypto.1.0.0.dylib $buildLocation/lib/

	#if [[ $buildHadoopFDW -eq 1 ]]; then
	#	cp $sharedLibs/libjvm.* $buildLocation/lib/
	#fi

        if [[ $buildCassandraFDW -eq 1 ]]; then
               cp $sharedLibs/libcassandra.2.dylib $buildLocation/lib/
               cp $sharedLibs/libuv.1.dylib $buildLocation/lib/
        fi

	if [[ $buildPgBouncer -eq 1 ]]; then
		cp $sharedLibs/libevent-2.0.5.dylib $buildLocation/lib/
		#cp $sharedLibs/libssl.1.0.0.dylib $buildLocation/lib/
		#cp $sharedLibs/libcrypto.1.0.0.dylib $buildLocation/lib/
	fi

	if [[ $buildSpatial -eq 9 ]]; then
		cp $projLib/lib/libproj.9.dylib $buildLocation/lib/
		cp $geosLib/lib/libgeos_c.1.dylib $buildLocation/lib/
		cp $geosLib/lib/libgeos-3.5.0.dylib $buildLocation/lib/
		cp $gdalLib/lib/libgdal.1.dylib $buildLocation/lib/
		###cp $xml2Lib/lib/libxml2.2.dylib $buildLocation/lib/
		cp /usr/lib/libxml2.2.dylib $buildLocation/lib/
		
	fi
}

# This function updates the library linking paths for libs and binaries
function updateSharedLibPaths {
	cd $buildLocation/bin

	install_name_tool -change /opt/pgbin-build/pgbin/shared/osx_64/lib/libssl.1.0.0.dylib "@executable_path/../lib/libssl.1.0.0.dylib" postgres >> $baseDir/$workDir/logs/libPath.log 2>&1
	install_name_tool -change /opt/pgbin-build/pgbin/shared/osx_64/lib/libcrypto.1.0.0.dylib "@executable_path/../lib/libcrypto.1.0.0.dylib" postgres >> $baseDir/$workDir/logs/libPath.log 2>&1

	install_name_tool -change /opt/pgbin-build/pgbin/shared/osx_64/lib/libssl.1.0.0.dylib "@executable_path/../lib/libssl.1.0.0.dylib" psql >> $baseDir/$workDir/logs/libPath.log 2>&1
	install_name_tool -change /opt/pgbin-build/pgbin/shared/osx_64/lib/libcrypto.1.0.0.dylib "@executable_path/../lib/libcrypto.1.0.0.dylib" psql >> $baseDir/$workDir/logs/libPath.log 2>&1


	for file in `ls *` ; do
		install_name_tool -change $buildLocation/lib/libpq.5.dylib "@executable_path/../lib/libpq.5.dylib" "$file" >> $baseDir/$workDir/logs/libPath.log 2>&1
		install_name_tool -change @rpath/libjvm.dylib "@executable_path/../lib/libjvm.dylib" "$file" >> $baseDir/$workDir/logs/libPath.log 2>&1
		install_name_tool -delete_rpath $sharedLibs -add_rpath @executable_path/../lib "$file" >> $baseDir/$workDir/logs/libPath.log 2>&1
	done
	
	if [[ $buildPgBouncer -eq 1 ]]; then
		#install_name_tool -change $buildLocation/lib/libevent-2.0.5.dylib "@executable_path/../lib/libevent-2.0.5.dylib" pgbouncer >> $baseDir/$workDir/logs/libPath.log 2>&1
		install_name_tool -change $(otool -L pgbouncer | grep libevent | awk '{print $1}') @executable_path/../lib/libevent-2.0.5.dylib pgbouncer >> $baseDir/$workDir/logs/libPath.log 2>&1
		install_name_tool -change $(otool -L pgbouncer | grep libssl.1.0.0.dylib | awk '{print $1}') @executable_path/../lib/libssl.1.0.0.dylib pgbouncer >> $baseDir/$workDir/logs/libPath.log 2>&1
		install_name_tool -change $(otool -L pgbouncer | grep libcrypto.1.0.0.dylib | awk '{print $1}') @executable_path/../lib/libcrypto.1.0.0.dylib pgbouncer >> $baseDir/$workDir/logs/libPath.log 2>&1
	fi

	cd $buildLocation/lib
		chmod 755 libssl.1.0.0.dylib	
		install_name_tool -change /opt/pgbin-build/pgbin/shared/osx_64/lib/libcrypto.1.0.0.dylib "@executable_path/../lib/libcrypto.1.0.0.dylib" libssl.1.0.0.dylib >> $baseDir/$workDir/logs/libPath.log 2>&1
		chmod 555 libssl.1.0.0.dylib	
		install_name_tool -change /opt/pgbin-build/pgbin/shared/osx_64/lib/libcrypto.1.0.0.dylib "@executable_path/../lib/libcrypto.1.0.0.dylib" libpq.5.dylib >> $baseDir/$workDir/logs/libPath.log 2>&1
		install_name_tool -change /opt/pgbin-build/pgbin/shared/osx_64/lib/libssl.1.0.0.dylib "@executable_path/../lib/libssl.1.0.0.dylib" libpq.5.dylib >> $baseDir/$workDir/logs/libPath.log 2>&1
		install_name_tool -change $(otool -L libcassandra.2.dylib | grep libuv | awk '{print $1}') "@executable_path/../lib/libuv.1.dylib" libcassandra.2.dylib >> $baseDir/$workDir/logs/libPath.log 2>&1
		install_name_tool -change $(otool -L libcassandra.2.dylib | grep libssl.1.0.0 | awk '{print $1}') "@executable_path/../lib/libssl.1.0.0.dylib" libcassandra.2.dylib >> $baseDir/$workDir/logs/libPath.log 2>&1
		install_name_tool -change $(otool -L libcassandra.2.dylib | grep libcrypto.1.0.0 | awk '{print $1}') "@executable_path/../lib/libcrypto.1.0.0.dylib" libcassandra.2.dylib >> $baseDir/$workDir/logs/libPath.log 2>&1

	for file in `ls *dylib*` ; do
		install_name_tool -change $buildLocation/lib/libpq.5.dylib "@executable_path/../lib/libpq.5.dylib" "$file" >> $baseDir/$workDir/logs/libPath.log 2>&1
		#LINUX chrpath -r "\${ORIGIN}/../lib" "$file" >> $baseDir/$workDir/logs/libPath.log 2>&1 
		install_name_tool -delete_rpath $sharedLibs -add_rpath @executable_path/../lib "$file"  >> $baseDir/$workDir/logs/libPath.log 2>&1
	done

	if [[ -d "$buildLocation/lib/postgresql" ]]; then	
		cd $buildLocation/lib/postgresql

        	for file in `ls *.so` ; do
			install_name_tool -change $buildLocation/lib/libpq.5.dylib "@executable_path/../lib/libpq.5.dylib" "$file" >> $baseDir/$workDir/logs/libPath.log 2>&1
                	#chrpath -r "\${ORIGIN}/../../lib" "$file" >> $baseDir/$workDir/logs/libPath.log 2>&1
			install_name_tool -delete_rpath $sharedLibs -add_rpath @executable_path/../lib "$file" >> $baseDir/$workDir/logs/libPath.log 2>&1
        	done
			install_name_tool -change /opt/pgbin-build/pgbin/shared/osx_64/lib/libssl.1.0.0.dylib "@executable_path/../lib/libssl.1.0.0.dylib" sslinfo.so >> $baseDir/$workDir/logs/libPath.log 2>&1
			install_name_tool -change /opt/pgbin-build/pgbin/shared/osx_64/lib/libcrypto.1.0.0.dylib "@executable_path/../lib/libcrypto.1.0.0.dylib" sslinfo.so >> $baseDir/$workDir/logs/libPath.log 2>&1

			install_name_tool -change /opt/perl516/lib/5.16.3/darwin-2level/CORE/libperl.dylib libperl.dylib plperl.so >> $baseDir/$workDir/logs/libPath.log 2>&1
			install_name_tool -change libcassandra.2.dylib "@executable_path/../lib/libcassandra.2.dylib" cassandra_fdw.so >> $baseDir/$workDir/logs/libPath.log 2>&1
	fi
	
	if [[ $buildSpatial -eq 99 ]]; then
	echo "Adding libraries for PostGIS"
		cd $buildLocation/bin
		#Update pgsql2shp
		echo "Fixing pgsql2shp"
		install_name_tool -change $(otool -L pgsql2shp | grep liblwgeom | awk '{print $1}') @executable_path/../lib/liblwgeom-2.2.5.dylib pgsql2shp
		install_name_tool -change $(otool -L pgsql2shp | grep libpq | awk '{print $1}') @executable_path/../lib/libpq.5.dylib pgsql2shp
		
		echo "Fixing shp2pgsql"
		install_name_tool -change $(otool -L shp2pgsql | grep liblwgeom-2.2.5.dylib | awk '{print $1}') @executable_path/../lib/liblwgeom-2.2.5.dylib shp2pgsql

		echo "Fixing raster2pgsql"
		install_name_tool -change $(otool -L raster2pgsql | grep liblwgeom-2.2.5.dylib | awk '{print $1}') @executable_path/../lib/liblwgeom-2.2.5.dylib raster2pgsql
		install_name_tool -change $(otool -L raster2pgsql | grep libproj.9.dylib | awk '{print $1}') @executable_path/../lib/libproj.9.dylib raster2pgsql
		install_name_tool -change $(otool -L raster2pgsql | grep libgdal.1.dylib | awk '{print $1}') @executable_path/../lib/libgdal.1.dylib raster2pgsql 
		install_name_tool -change $(otool -L raster2pgsql | grep libgeos_c.1.dylib | awk '{print $1}') @executable_path/../lib/libgeos_c.1.dylib raster2pgsql 
		install_name_tool -change $(otool -L raster2pgsql | grep libgeos-3.5.0.dylib | awk '{print $1}') @executable_path/../lib/libgeos-3.5.0.dylib raster2pgsql
		install_name_tool -change $(otool -L raster2pgsql | grep libxml2.2.dylib | awk '{print $1}') @executable_path/../lib/libxml2.2.dylib raster2pgsql 

		echo "Fixing liblwgeom"
		cd $buildLocation/lib
		install_name_tool -change $(otool -L liblwgeom-2.2.5.dylib | grep libgeos_c.1.dylib | awk '{print $1}') @executable_path/../lib/libgeos_c.1.dylib liblwgeom-2.2.5.dylib
		#install_name_tool -change $(otool -L liblwgeom-2.2.5.dylib | grep libgeos-3.5.0.dylib | awk '{print $1}') @executable_path/../lib/libgeos-3.5.0.dylib liblwgeom-2.2.5.dylib 
		install_name_tool -change $(otool -L liblwgeom-2.2.5.dylib | grep libproj.9.dylib | awk '{print $1}') @executable_path/../lib/libproj.9.dylib liblwgeom-2.2.5.dylib

		echo "Fixing libgeos"
		install_name_tool -change $(otool -L libgeos_c.1.dylib | grep libgeos-3.5.0.dylib | awk '{print $1}') @executable_path/../lib/libgeos-3.5.0.dylib libgeos_c.1.dylib

		echo "Fixing rtpostgis"
		cd $buildLocation/lib/postgresql
		install_name_tool -change $(otool -L rtpostgis-2.2.so | grep libgdal | awk '{print $1}') @executable_path/../lib/libgdal.1.dylib rtpostgis-2.2.so
		install_name_tool -change $(otool -L rtpostgis-2.2.so | grep libgeos_c.1.dylib | awk '{print $1}') @executable_path/../lib/libgeos_c.1.dylib rtpostgis-2.2.so
		install_name_tool -change $(otool -L rtpostgis-2.2.so | grep libproj.9.dylib | awk '{print $1}') @executable_path/../lib/libproj.9.dylib rtpostgis-2.2.so

		echo "Fixing postgis_topology"
		install_name_tool -change $(otool -L postgis_topology-2.2.so | grep libproj | awk '{print $1}') @executable_path/../lib/libproj.9.dylib postgis_topology-2.2.so
		install_name_tool -change $(otool -L postgis_topology-2.2.so | grep libgeos_c | awk '{print $1}') @executable_path/../lib/libgeos_c.1.dylib postgis_topology-2.2.so 

		echo "Fixing postgis.so"
		install_name_tool -change $(otool -L postgis-2.2.so | grep libgeos_c | awk '{print $1}') @executable_path/../lib/libgeos_c.1.dylib postgis-2.2.so
		install_name_tool -change $(otool -L postgis-2.2.so | grep libproj.9.dylib | awk '{print $1}') @executable_path/../lib/libproj.9.dylib postgis-2.2.so
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
	pgbinTar="pg$pgShortVersion-$pgSourceVersion-$pgBuildVersion-osx64"
	
	tar -cjf "$pgbinTar.tar.bz2" "pg$pgShortVersion-$pgSourceVersion-$pgBuildVersion-osx64" >> $baseDir/$workDir/logs/tar.log 2>&1
	
	if [[ $? -ne 0 ]]; then
		echo "Unable to create tar for $buildLocation, check logs .... "
	else
		mkdir -p $archiveDir/$workDir
		mv "$pgbinTar.tar.bz2" $archiveDir/$workDir/
                cd /opt/pgcomponent
                pgCompDir="pg$pgShortVersion"
                rm -rf $pgCompDir
                mkdir $pgCompDir && tar -xf "$archiveDir/$workDir/$pgbinTar.tar.bz2" --strip-components=1 -C $pgCompDir
                
                destDir=`date +%Y-%m-%d`
                #ssh build@10.0.1.151 "mkdir -p /opt/pgbin-builds/$destDir"
                #scp "$archiveDir/$workDir/$pgbinTar.tar.bz2" build@10.0.1.151:/opt/pgbin-builds/$destDir/

	fi
}

if [[ $# -lt 1 ]]; then
	printUsage
	exit 1
fi

	while getopts "t:a:s:b:n:d:f:o:g:q:c:j:l:u:i:p:vh" opt; do
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
			f)
                                if [[ $OPTARG = -* ]]; then
                                        ((OPTIND--))
                                        continue
                                fi
                                buildOrafce=1
                                orafceSource=$OPTARG
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
				oracleFDWSourceTar=$OPTARG
			;;
                        i)
                                if [[ $OPTARG = -* ]]; then
                                        ((OPTIND--))
                                        continue
                                fi
                                buildPGAudit=1
                                pgAuditSource=$OPTARG
                        ;;
                        u)
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

