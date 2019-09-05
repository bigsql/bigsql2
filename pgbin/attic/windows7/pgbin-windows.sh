#!/bin/bash
#
# This script generates a Windows relocatable build for PostgreSQL using mingw
# The script can additionally build pgbouncer and PostGIS
# The PostgreSQL build includes all the contrib modules, support openssl
# The script required OpenSSL, Libreadline, termcap, libz etc available under $sharedLibs
# To build PostGIS, the script requires GEOS, GDAL, PROJ and XML2.
# The script also requires Strawberry Perl 5.2xs, Python 2.7(official) and TCL 8.6+
#
# Author: Farrukh Afzal (farrukha@openscg.com)
# 
# Revision History
# ===========================================================================
# Date        |  Author       |    Description                                            
# ===========================================================================
# 2015-11-25  | Farrukh       |    Initial Implementation of pgBin for Windows.
# 2015-12-2  | Farrukh       |    Added support for TD
#============================================================================
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
export ORACLE_HOME="/opt/pgbin-build/pgbin/shared/instantclient_10_2/instantclient_10_2/"

pgTarLocation=""
pgSourceDir=""
pgMajorVersion=0
pgMinorVersion=0
pgMicroVersion=0
pgSourceVersion=""
pgBuildVersion=0

pgBouncerSourceDir=""
pgBouncerSourceVer=""

odbcSourceDir=""
odbcSourceVersion=""
odbcSourceTar=""
plJavaSource="/opt/pgbin-build/sources/pljava-1_5_0.tar.gz"
plv8Source="/opt/pgbin-build/sources/plv8-2.0.3.tar.gz"

postgisSourceDir=""
postgisSourceVersion=""
postgisSourceTar=""
orafceSource=""
tdsFDWSource=""
pgAuditSource=""
setUserSource=""

geosLib="/opt/gis-tools/geos350"
gdalLib="/opt/gis-tools/gdal2"
xml2Lib="/opt/gis-tools/libxml2"
projLib="/opt/gis-tools/proj4"

sourceTarPassed=0
archiveLocationPassed=0
buildVersionPassed=0
buildPgBouncer=0
buildSpatial=0
buildHadoopFDW=0
buildCassandraFDW=0
buildODBC=0
buildPgTSQL=0
buildOrafce=0
buildPlJava=0
buildOrafce=0
buildTDSFDW=0
buildOracleFDW=0
buildSetUser=0
buildPGAudit=0
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
	-d      Build Hadoop FDW, Provide Hadoop FDW source tar ball.
	-g	Add pgHA to the build, provide pgHA source.
        -n      Build number, defaults to 1.
        -j      JDK path
        -o      Build ODBC support, provide pgsql ODBC source tar ball.
        -q      Build pgTSQL, Provide pgTSQL source tar ball.
        -s      Build spatial(PostGIS), provide PostGIS source tar ball.
        -f      Build orafce, provide orafce source tar ball.
	-l      Build Oracle FDW, provide source tar ball.
	-y	Build TDS FDW, provide TDS FDW source tar ball.
	-u	Build Set-User extentions, provide source tar ball.
	-i	Build PG Audit extension, provide source tar ball.
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
	tar -xf $pgTarLocation
		
	isPgConfigure=`$pgSourceDir/configure --version | head -1 | grep "PostgreSQL configure" | wc -l`
	
	if [[ $isPgConfigure -ne 1 ]]; then
		echo "$tarFileName is not a valid postgresql source tarball .... "
		exit 1
	else
		pgSourceVersion=`$pgSourceDir/configure --version | head -1 | awk '{print $3}'`
		pgMajorVersion=`echo $pgSourceVersion | awk -F '.' '{print $1}'`
		pgMinorVersion=`echo $pgSourceVersion | awk -F '.' '{print $2}'`
		pgMicroVersion=`echo $pgSourceVersion | awk -F '.' '{print $3}'`
        #if [[ "${pgSourceVersion/rc}" == "10devel" || "${pgSourceVersion/rc}" == "10beta2" ]]; then
        if [[ "${pgSourceVersion/rc}" =~ 11.* ]]; then
            pgShortVersion="11"
        elif [[ "${pgSourceVersion/rc}" == 10* ]]; then
            pgShortVersion="10"
        elif [[ "${pgSourceVersion/rc}" == "$pgSourceVersion" ]]; then
            pgShortVersion="`echo $pgSourceVersion | awk -F '.' '{print $1$2}'`"
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
		postgisSourceVersion=`cat Version.config | grep MAJOR | awk 'BEGIN {FS = "=" } ; {print $2}'`
		postgisSourceVersion="$postgisSourceVersion."`cat Version.config | grep MINOR | awk 'BEGIN {FS = "=" } ; {print $2}'`
		postgisSourceVersion="$postgisSourceVersion."`cat Version.config | grep MICRO | awk 'BEGIN {FS = "=" } ; {print $2}'`
		echo "Postgis $postgisSourceVersion source tarball .... OK "
	fi
}

# This function build ore postgresql
# including all the contribs and Hadoop_FDW, if requested.
function buildPostgres {

	echo "Starting PostgreSQL $pgSourceVersion build ...."
	sleep 2
	
	cd $baseDir/$workDir/$pgSourceDir

	#more configure | grep perl_lib
	#if [[ "${pgSourceVersion}" == "10devel" || "${pgSourceVersion}" == "10beta1" ]]; then
        if [[ "${pgSourceVersion/rc}" =~ 10.* || "${pgSourceVersion/rc}" =~ 11.* ]]; then
			sed -i 's/basename $perl_archlibexp\/CORE\/perl\[5-9\]\*\.lib \.lib/basename $perl_archlibexp\/CORE\/libperl\[5-9\]\*\.a \.a/g' configure
			sed -i 's/$perl_archlibexp\/CORE\/$perl_lib\.lib/$perl_archlibexp\/CORE\/$perl_lib\.a/g' configure
			sed -i 's/-L$perl_archlibexp\/CORE -l$perl_lib/-L$perl_archlibexp\/CORE -lperl520/g' configure
	elif [[ $pgMajorVersion -eq 9 && "$pgMinorVersion" = "6rc1" ]]; then
			sed -i 's/basename $perl_archlibexp\/CORE\/perl\[5-9\]\*\.lib \.lib/basename $perl_archlibexp\/CORE\/libperl\[5-9\]\*\.a \.a/g' configure
			sed -i 's/$perl_archlibexp\/CORE\/$perl_lib\.lib/$perl_archlibexp\/CORE\/$perl_lib\.a/g' configure
			sed -i 's/-L$perl_archlibexp\/CORE -l$perl_lib/-L$perl_archlibexp\/CORE -lperl520/g' configure
	else
		if [[ $pgMajorVersion -eq 9 && $pgMinorVersion -ge 3 ]]; then
			echo "Fixing configure script to build plPerl for PostgreSQL 9.3+"
			sed -i 's/basename $perl_archlibexp\/CORE\/perl\[5-9\]\*\.lib \.lib/basename $perl_archlibexp\/CORE\/libperl\[5-9\]\*\.a \.a/g' configure
			sed -i 's/$perl_archlibexp\/CORE\/$perl_lib\.lib/$perl_archlibexp\/CORE\/$perl_lib\.a/g' configure
			sed -i 's/-L$perl_archlibexp\/CORE -l$perl_lib/-L$perl_archlibexp\/CORE -lperl520/g' configure
		fi
	
		if [[ $pgMajorVersion -eq 9 && $pgMinorVersion -le 2 ]]; then
			echo "Fixing configure script to build plPerl for PostgreSQL 9.2-"
			cd src/pl/plperl
			sed -i 's/CORE\/libperl\[5-9\]\*\.lib/CORE\/libperl\[5-9\]\*\.a/g' GNUmakefile
			sed -i 's/CORE -l\$(perl_lib)/CORE -l\perl520/g' GNUmakefile
		fi
	fi
	cd $baseDir/$workDir/$pgSourceDir
	
	#more configure | grep perl_lib
	
	echo "Configure Script fixed .... "
	
	echo "Running PostgreSQL configure .... "		
	
	mkdir -p $baseDir/$workDir/logs
	
	if [[ $buildVersionPassed -eq 1 ]]; then
		pgBuildVersion="$pgBuildVersion"
	else
		pgBuildVersion="1"	
	fi

	
	buildLocation="$baseDir/$workDir/build/pg$pgShortVersion-$pgSourceVersion-$pgBuildVersion-win64"
	#if [[ $pgShortVersion == "96" || $pgShortVersion == "10" || $pgShortVersion == "11" ]]; then
		configCommand="./configure --prefix=$buildLocation --enable-integer-datetimes --enable-thread-safety --with-libxml --with-libxslt --with-ossp-uuid --enable-nls --with-openssl --with-ldap --with-python --with-perl --with-tcl --with-libraries=/opt/pgbin-build/pgbin/shared/win64/lib:/usr/local/lib:/usr/local/ssl/lib --with-includes=/usr/local/include:/usr/local/ssl/include"
	#else
		#configCommand="./configure --prefix=$buildLocation --enable-integer-datetimes --enable-thread-safety --with-libxml --with-libxslt --with-ossp-uuid --enable-nls --with-openssl --with-python --with-perl --with-tcl --with-libraries=/opt/pgbin-build/pgbin/shared/win64/lib:/usr/local/lib:/usr/local/ssl/lib --with-includes=/usr/local/include:/usr/local/ssl/include"
	#fi
	#configCommand="./configure --prefix=$buildLocation --enable-integer-datetimes --with-libxml --with-libxslt --with-ossp-uuid --enable-nls --with-openssl --with-python --with-tcl --with-libraries=/usr/local/lib:/usr/local/ssl/lib --with-includes=/usr/local/include:/usr/local/ssl/include"
	
	oldPath=`echo $PATH`
	export PATH=/usr/local/bin:/usr/local/ssl/bin:/c/tcl864/bin:$PATH
	
	export CFLAGS="-O2 -DMS_WIN64 -I/opt/pgbin-build/pgbin/shared/win64/include"
	#export LDFLAGS="-L/opt/pgbin-build/pgbin/shared/win64/lib"

	#DEBUG echo "Configure command : $configCommand"
	$configCommand > $baseDir/$workDir/logs/configure.log 2>&1

	if [[ $? -ne 0 ]]; then
		echo "Postgresql $pgSourceVersion configure failed, check $baseDir/$workDir/$pgSourceDir/config.log .... "
		exit
	fi

	echo "Configure completed successfuly .... "
	sleep 4
	echo "Running PostgreSQL make .... "
	make -j 6 > $baseDir/$workDir/logs/make.log 2>&1
	
	if [[ $? -ne 0 ]]; then
		echo "Make failed, check the logs .... "
		exit 1
	fi

	echo "Make finished sucessfully .... "
	sleep 2

	echo "Installing PostgreSQL Core build .... "
	make install > $baseDir/$workDir/logs/make_install.log 2>&1
	
      if [[ $? -ne 0 ]]; then
                echo "Build installation failed, check the logs .... "
                exit 1
        fi

	echo "Building contrib modules .... "

	cd $baseDir/$workDir/$pgSourceDir/contrib

	make > $baseDir/$workDir/logs/contrib_make.log 2>&1
	if [[ $? -eq 0 ]]; then
		make install > $baseDir/$workDir/logs/contrib_install.log 2>&1
		if [[ $? -ne 0 ]]; then
			echo "Failed to install contrib modules ...."
		fi

#		if [[ $pgShortVersion != "96" ]]; then	
#                	tar -xf /opt/pgbin-build/sources/pldebugger.tar.gz
#                	cd pldebugger
#               		make > $baseDir/$workDir/logs/pldebugger_make.log 2>&1
#                	make install > $baseDir/$workDir/logs/pldebugger_install.log 2>&1
#		fi

                # cd $baseDir/$workDir/$pgSourceDir/contrib
                # mkdir plprofiler && tar -xf /opt/pgbin-build/sources/plprofiler_2.0aplha2.tar.gz --strip-components=1 -C plprofiler
                # cd plprofiler
		# oldPath=$PATH
		# PATH="$buildLocation/bin:$PATH"
                # make > $baseDir/$workDir/logs/plprofiler_make.log 2>&1
                # make install > $baseDir/$workDir/logs/plprofiler_install.log 2>&1
		# PATH=$oldPath
				
	#Build orafce if requested.
	oldPath=$PATH
	PATH="$buildLocation/bin:$PATH"
	#echo $PATH
	if [[ $buildOrafce -eq 1 ]]; then
		cd $baseDir/$workDir/$pgSourceDir/contrib
		mkdir orafce && tar -xf $orafceSource --strip-components=1 -C orafce
		cd orafce
		make > $baseDir/$workDir/logs/orafce_make.log 2>&1
		if [[ $? -eq 0 ]]; then
			make install > $baseDir/$workDir/logs/orafce_install.log 2>&1
			if [[ $? -ne 0 ]]; then
				echo "Failed to install orafce contrib ..."
			fi
		else
			echo "Make failed for orafce ..."
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

	
        if [[ $buildPlJava -eq 1 ]]; then
                #PATH=/usr/java/jdk1.5.0_22/bin:$PATH
                PATH=/opt/maven/bin:$PATH
                cd $baseDir/$workDir/$pgSourceDir/contrib
                mkdir pljava && tar -xf $plJavaSource --strip-components=1 -C pljava
                cd pljava
                mvn clean install > $baseDir/$workDir/logs/pljava_make.log 2>&1
                if [[ $? -eq 0 ]]; then
                        java -jar "pljava-packaging/target/pljava-pg`echo $pgSourceVersion | awk -F '.' '{print $1"."$2}'`-amd64-Windows-gpp.jar" > $baseDir/$workDir/logs/pljava_install.log 2>&1
                        if [[ $? -ne 0 ]]; then
                                echo "Failed to install plJava ..."
                        fi
                fi
        fi

		

	else
		echo "Failed to build conrib modules, check logs .... "
	fi


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
    fi
	
	# building cassacdra fdw
	
	if [[ $buildCassandraFDW -eq 1 ]]; then
   		cd $baseDir/$workDir/$pgSourceDir/contrib
        mkdir cassandra2c_fdw && tar -xf $cassandraSourceTar --strip-components=1 -C cassandra2c_fdw
		cd cassandra2c_fdw
        
        echo -e "Running CassandraFDW make install ...."
        USE_PGXS=1 make > $baseDir/$workDir/logs/cassandrafdw_make.log 2>&1
            if [[ $? -eq 0 ]]; then
				make install > $baseDir/$workDir/logs/cassandrafdw_makeinstall.log 2>&1
				if [[ $? -ne 0 ]]; then
                       echo "Cassandra FDW make installation failed ...."
                fi
            else
                echo "CassandraFDW make failed. Please check the logs .... "
            fi
    fi
	
	if [[ $buildOracleFDW -eq 1 ]]; then
		cd $baseDir/$workDir/$pgSourceDir/contrib
		mkdir oracle_fdw && tar -xf $oracleFDWSourceTar --strip-components=1 -C oracle_fdw
		cd oracle_fdw
		echo $ORACLE_HOME
		make > $baseDir/$workDir/logs/oraclefdw_make.log 2>&1
		if [[ $? -eq 0 ]]; then
			make install > $baseDir/$workDir/logs/oraclefdw_install.log 2>&1
			if [[ $? -ne 0 ]]; then
				echo " Oracle FDW Make Install failed .... "
			fi
		else
			echo "Oracle FDW make failed .... "
		fi
	fi

		
	# building pgTSQL
	if [[ $buildPgTSQL -eq 1 ]]; then
        cp $pgTSQLSourceTar $baseDir/$workDir/$pgSourceDir/contrib
		pgTSQLSourceDir=`dirname $(tar -tf $pgTSQLSourceTar | grep pgtsql.control)`
		cd $baseDir/$workDir/$pgSourceDir/contrib
        tar -xzf $pgTSQLSourceTar
		cd $pgTSQLSourceDir
                export PATH="$buildLocation/bin:$PATH"
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

	#
	
	if [[ $buildTDSFDW -eq 1 ]]; then
		echo "Building TDS FDW ..."
		cd $baseDir/$workDir/$pgSourceDir/contrib
		mkdir tds_fdw && tar -xf $tdsFDWSource --strip-components=1 -C tds_fdw
		cd tds_fdw
		make > $baseDir/$workDir/logs/tds_make.log 2>&1
		if [[ $? -eq 0 ]]; then
			make install > $baseDir/$workDir/logs/tds_makeinstall.log 2>&1
			if [[ $? -ne 0 ]]; then
				echo "Make install failed for TDS FDW ...."
			fi			
		fi
	fi	

        if [[ $buildPLV8 -eq 1 ]]; then
		echo "Building PL/V8 ..."
                cd $baseDir/$workDir/$pgSourceDir/contrib
                mkdir -p plv8 && tar -xf $plv8Source --strip-components=1 -C plv8
                cd plv8
                #tar -xf /opt/pgbin-build/sources/v8_build.tar.gz
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

	# Docs don't build successfully inside of MingW because of missing dependencies.
	# So we add pre-generated HTML docs for each specific version.
	
	cd $buildLocation/share/doc/postgresql
	tar -xf /opt/pgbin-build/sources/pgdocs_$pgSourceVersion.tar.bz2
	
	PATH=$oldPath
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

	
	#./configure --prefix=$buildLocation --with-libevent=$sharedLibs/../ --with-openssl=$sharedLibs/../ LDFLAGS="-Wl,-rpath,$sharedLibs" > $baseDir/$workDir/logs/pgbouncer_configure.log 2>&1
	./configure --prefix=$buildLocation --disable-debug --enable-evdns --without-cares --with-libevent=/opt/pgbin-build/pgbin/shared/win64 > $baseDir/$workDir/logs/pgbouncer_configure.log 2>&1
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

	#LD_RUN_PATH=$buildLocation/lib
	#export LD_LIBRARY_PATH=$sharedLibs:$buildLocation/lib
	export LDFLAGS="-L$buildLocation/lib"
	export CFLAGS="$CFLAGS -I$buildLocation/include/postgresql/server/port/win32"
	
	#./configure --prefix=$buildLocation --with-pgconfig=$buildLocation/bin/pg_config --with-geosconfig=$geosLib/bin/geos-config --with-projdir=$projLib --with-xml2config=$xml2Lib/bin/xml2-config --with-gdalconfig=$gdalLib/bin/gdal-config LDFLAGS=-Wl,-rpath,'$$ORIGIN'/../lib/ > $baseDir/$workDir/logs/postgis_configure.log 2>&1
	./configure --prefix=$buildLocation --with-pgconfig=$buildLocation/bin/pg_config --with-geosconfig=$geosLib/bin/geos-config --with-projdir=$projLib --with-gdalconfig=$gdalLib/bin/gdal-config --enable-static=yes --enable-shared=no > $baseDir/$workDir/logs/postgis_configure.log 2>&1
	
        if [[ $? -ne 0 ]]; then
                echo "Postgis configure failed, check config.log for details ...."
                return 1
        fi
		
	cd libpgcommon
	#mv Makefile Makefile_orig
	#AR1=`cat Makefile_orig | grep ^CFLAGS`
	#VAR1="$VAR1 -I$buildLocation/include/postgresql/server/port/win32"
	#(echo $VAR1 && cat Makefile_orig | grep -v ^CFLAGS) > Makefile
	
	cd $baseDir/$workDir/$postgisSourceDir
	
	make > $baseDir/$workDir/logs/postgis_make.log 2>&1

    if [[ $? -ne 0 ]]; then

            echo "Postgis make failed, check logs .... "
    fi
    #mv $buildLocation "${buildLocation}_master"
    #mkdir -p "$buildLocation/lib/postgresql/pgxs/src/makefiles/"
    #mkdir -p "$buildLocation/bin"
    #cp "${buildLocation}_master/bin/pg_config" "${buildLocation}/bin"
    #cp "${buildLocation}_master/lib/postgresql/pgxs/src/makefiles/pgxs.mk" "${buildLocation}/lib/postgresql/pgxs/src/makefiles/pgxs.mk"
    #cp "${buildLocation}_master/lib/postgresql/pgxs/src/Makefile.global" "${buildLocation}/lib/postgresql/pgxs/src/"
    #cp "${buildLocation}_master/lib/postgresql/pgxs/src/Makefile.port" "${buildLocation}/lib/postgresql/pgxs/src/"
    #cp "${buildLocation}_master/lib/postgresql/pgxs/src/Makefile.shlib" "${buildLocation}/lib/postgresql/pgxs/src/"
    #make install >  $baseDir/$workDir/logs/postgis_install.log 2>&1
    #mv $buildLocation "$baseDir/$workDir/build/$postgisBundle"
    #mv "${buildLocation}_master" $buildLocation
	
	#make install >  $baseDir/$workDir/logs/postgis_install.log 2>&1

	if [[ $? -ne 0 ]]; then 
        echo "Failed to install Postgis, check logs .... "
 	else
        echo "Postgis built & installed successfully .... "
	fi

	unset LD_LIBRARY_PATH
}

# This function adds the required libs to the build
function copySharedLibs {
	
	echo "Adding shared libs to the new build ...."
	cp /mingw64/bin/libintl-8.dll $buildLocation/bin/
	cp /mingw64/bin/libiconv-2.dll $buildLocation/bin/
	cp /usr/local/bin/libxml2-2.dll $buildLocation/bin/
	cp /usr/local/bin/libxslt-1.dll $buildLocation/bin/
	cp /mingw64/bin/zlib1.dll $buildLocation/bin/
	cp /mingw64/bin/libeay32.dll $buildLocation/bin/
	cp /mingw64/bin/ssleay32.dll $buildLocation/bin/
	cp /mingw64/bin/libgcc_s_seh-1.dll $buildLocation/bin/
	#cp /mingw64/bin/libstdc++-6.dll $buildLocation/bin/
	cp /mingw64/bin/libwinpthread-1.dll $buildLocation/bin/
	#cp /usr/local/bin/libsybdb-5.dll $buildLocation/bin
	#cp /opt/pgbin-build/pgbin/shared/win64/bin/libcassandra.dll $buildLocation/bin/
	#cp /opt/pgbin-build/pgbin/shared/win64/bin/libuv-1.dll $buildLocation/bin/
	
	if [[ $buildPgBouncer -eq 1 ]]; then
		cp /opt/pgbin-build/pgbin/shared/win64/bin/libevent-2-0-5.dll $buildLocation/bin/
	fi

	if [[ $buildSpatial -eq 9 ]]; then
		cp $projLib/bin/libproj-9.dll $buildLocation/bin/
		cp $gdalLib/bin/libgdal-20.dll $buildLocation/bin/
		cp $geosLib/bin/libgeos_c-1.dll $buildLocation/bin/
		cp $geosLib/bin/libgeos-3-5-0.dll $buildLocation/bin/
		
		cp /mingw64/bin/libcurl-4.dll $buildLocation/bin/
		cp /mingw64/bin/librtmp-1.dll $buildLocation/bin/
		cp /mingw64/bin/libidn-11.dll $buildLocation/bin/
		cp /mingw64/bin/libssh2-1.dll $buildLocation/bin/
		cp /mingw64/bin/libgnutls-30.dll $buildLocation/bin/
		cp /mingw64/bin/libgmp-10.dll $buildLocation/bin/
		cp /mingw64/bin/libhogweed-4-1.dll $buildLocation/bin/
		cp /mingw64/bin/libnettle-6-1.dll $buildLocation/bin/
		cp /mingw64/bin/libtasn1-6.dll $buildLocation/bin/
		cp /mingw64/bin/libp11-kit-0.dll $buildLocation/bin/
		cp /mingw64/bin/libffi-6.dll $buildLocation/bin/		
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

	pgbinTar="pg$pgShortVersion-$pgSourceVersion-$pgBuildVersion-win64.tar.bz2"

	tar -cjf $pgbinTar "pg$pgShortVersion-$pgSourceVersion-$pgBuildVersion-win64" >> $baseDir/$workDir/logs/tar.log 2>&1
	
	if [[ $? -ne 0 ]]; then
		echo "Unable to create tar for $buildLocation, check logs .... "
	else
		mkdir -p $archiveDir/$workDir
		mv $pgbinTar $archiveDir/$workDir
		
		cd /opt/pgcomponent
        pgCompDir="pg$pgShortVersion"
        rm -rf $pgCompDir
        mkdir $pgCompDir && tar -xf "$archiveDir/$workDir/$pgbinTar" --strip-components=1 -C $pgCompDir
                
        destDir=`date +%Y-%m-%d`
        ssh -i /opt/ssh_key/build_key build@10.0.1.151 "mkdir -p /opt/pgbin-builds/$destDir"
        scp -i /opt/ssh_key/build_key "$archiveDir/$workDir/$pgbinTar" build@10.0.1.151:/opt/pgbin-builds/$destDir/
	fi
}

if [[ $# -lt 1 ]]; then
	printUsage
	exit 1
fi

	while getopts "t:a:s:b:n:d:f:o:g:q:c:j:y:l:u:i:vh" opt; do
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
			f)
				if [[ $OPTARG = -* ]]; then
					((OPTIND--))
					continue
				fi
				buildOrafce=1
				orafceSource=$OPTARG
			;;
			y)
				if [[ $OPTARG = -* ]]; then
					((OPTIND--))
					continue
				fi
				buildTDSFDW=1
				tdsFDWSource=$OPTARG
			;;
			l)
				if [[ $OPTARG = -* ]]; then
					((OPTIND--))
					continue
				fi
				buildOracleFDW=1
				oracleFDWSourceTar=$OPTARG
			;;
			u)
				if [[ $OPTARG = -* ]]; then
					((OPTIND--))
					continue
				fi
				buildSetUser=1
				setUserSource=$OPTARG
			;;
			i)
				if [[ $OPTARG = -* ]]; then
					((OPTIND--))
					continue
				fi
				buildPGAudit=1
				pgAuditSource=$OPTARG
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
	#Not needed on windoze  updateSharedLibPaths

	createPgbinBundle
fi
