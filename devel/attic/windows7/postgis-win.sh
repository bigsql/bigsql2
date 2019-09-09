#!/bin/bash
#
# This script generates a relocatable build for postgis    
#

#Define globals
archiveDir="/opt/builds/"
baseDir="`pwd`/.."
workDir="gis`date +%Y%m%d_%H%M`"
PGHOME=""

osArch=`getconf LONG_BIT`
 
sharedLibs="$baseDir/shared/linux_$osArch/lib"
sharedBins="$baseDir/shared/linux_$osArch/bin"
includePath="$baseDir/shared/linux_$osArch/include"
gdalLib="$baseDir/shared/win64"

pgBuildVersion=0
pgVersion=""

postgisSourceDir=""
postgisFullVersion=""
postgisShortVersion=""
postgisMajorVersion=""
postgisMinorVersion=""
postgisMicroVersion=""
postgisSourceTar=""
postgisBuildDir=""
gdalVer=2.2.0

xml2Lib="/opt/gis-tools/libxml2"
geosLib="/opt/gis-tools/geos-3.6.2"
projLib="/opt/gis-tools/proj4"
pcreLib="/opt/gis-tools/pcre-8.39"
jsonLib="/opt/gis-tools/json-c"

sourceTarPassed=0
archiveLocationPassed=0
buildVersionPassed=0
buildSpatial=0

# This function prints the script usage/help
function printUsage {

echo "

Usage:

`basename $0` [OPTIONS]

Required Options:
	-a      Target build location, the final tar.bz2 would be placed here
        -t      Postgis Source tar ball.
        -p      PostgreSQL HOME
";

}

# For postgis - Copy files from external dependencies. For example
# Files from $projLib/share/proj should be copied to share/postgresql/contrib/postgis-2.3/proj
function copyFilesFromExtDeps {
	cd $buildLocation/share/postgresql/contrib/postgis-$postgisMajorVersion.$postgisMinorVersion
	mkdir proj
	cp $projLib/share/proj/* proj/
}

# Verify if the Postgis tarball is valid
function checkPostgisTar {
	echo "Verifying PostGIS source tarball .... "

	cd $baseDir
	mkdir -p $workDir
	cd $baseDir/$workDir

	postgisSourceDir=`dirname $(tar -tf $postgisSourceTar | grep "README.postgis")`
	
	tar -xf $postgisSourceTar

	cd $postgisSourceDir

	isPostgisConfigure=`./configure --help | grep "geos" | wc -l`

	if [[ $isPostgisConfigure -ne 1 ]]; then
		echo "$postgisSourceTar is not a valid Postgis source tarball .... "
		return 1
	else
		postgisMajorVersion=`cat Version.config | grep MAJOR | awk 'BEGIN {FS = "=" } ; {print $2}'`
		postgisMinorVersion=`cat Version.config | grep MINOR | awk 'BEGIN {FS = "=" } ; {print $2}'`
		postgisMicroVersion=`cat Version.config | grep MICRO | awk 'BEGIN {FS = "=" } ; {print $2}'`
		postgisFullVersion="$postgisMajorVersion.$postgisMinorVersion.$postgisMicroVersion"
		postgisShortVersion="$postgisMajorVersion$postgisMinorVersion"
		echo "Postgis $postgisFullVersion source tarball .... OK "

		pgVersion=`$PGHOME/bin/pg_config --version | awk '{print $2}'`
		if [[ "${pgVersion/rc}" =~ 12.* ]]; then
			pgVersion=12
		elif [[ "${pgVersion/rc}" =~ 11.* ]]; then
			pgVersion=11
		elif [[ "${pgVersion/rc}" =~ 10.* ]]; then
			pgVersion=10
		fi
		
		#postgisBuildDir="postgis${postgisMajorVersion}${postgisMinorVersion}-${postgisFullVersion}-pg`echo $pgVersion | awk -F '.' '{print $1$2}'`-win64"
		#postgisBuildDir="postgis${postgisMajorVersion}${postgisMinorVersion}-pg`echo $pgVersion | awk -F '.' '{print $1$2}'`-${postgisFullVersion-2-win64"
		postgisBuildDir="postgis${postgisMajorVersion}${postgisMinorVersion}-pg`echo $pgVersion | awk -F '.' '{print $1$2}'`-${postgisFullVersion}-1-win64"

	fi
}



# This function builds PostGIS and adds to the build
function buildPostgis {
	echo "Building Postgis ...."

	buildLocation="$baseDir/$workDir/$postgisBuildDir"
	mkdir -p $buildLocation
	#Prepare the target directory
	mkdir -p $buildLocation/bin
	mkdir -p $buildLocation/lib
	mkdir -p $buildLocation/share
	mkdir -p $buildLocation/lib/postgresql
	cp -r $PGHOME/include $buildLocation/
	cp $PGHOME/bin/pg_config $buildLocation/bin/
	cp $gdalLib/gdal-${gdalVer}/bin/gdal-config $buildLocation/bin/
	cp $PGHOME/lib/libpq.* $buildLocation/lib/
	cp $PGHOME/lib/libpgport.a $buildLocation/lib/
	cp $PGHOME/lib/libpgcommon.a $buildLocation/lib/
	cp $PGHOME/lib/libpostgres.a $buildLocation/lib/
	cp -r $PGHOME/lib/postgresql/pgxs $buildLocation/lib/postgresql/

	mkdir -p $baseDir/$workDir/logs	
	
	if [[ ! -e $baseDir/$workDir/$postgisSourceDir ]]; then
		echo "Unable to build Postgis, source directory not found, check logs .... "
		return 1
	fi
	
	cp $postgisSourceTar $buildLocation/src.tar.gz
	

	cd $baseDir/$workDir/$postgisSourceDir

	cp LICENSE.TXT $buildLocation/LICENSE.TXT

	LD_RUN_PATH=$PGHOME/lib
	export LD_LIBRARY_PATH=$sharedLibs:$PGHOME/lib

	./configure --prefix=$buildLocation LDFLAGS="-L/opt/pgcomponent/pg10/lib" --with-pgconfig=$buildLocation/bin/pg_config --with-pcredir=$pcreLib --with-geosconfig=$geosLib/bin/geos-config --with-projdir=$projLib --with-jsondir=$jsonLib --with-gdalconfig=$buildLocation/bin/gdal-config  --enable-static=yes --enable-shared=no > $baseDir/$workDir/logs/postgis_configure.log 2>&1

        if [[ $? -ne 0 ]]; then
                echo "Postgis configure failed, check config.log for details ...."
                return 1
        fi
		
	cd libpgcommon
	mv Makefile Makefile_orig
	VAR1=`cat Makefile_orig | grep ^CFLAGS`
	VAR1="$VAR1 -I$buildLocation/include/postgresql/server/port/win32"
	(echo $VAR1 && cat Makefile_orig | grep -v ^CFLAGS) > Makefile	

	cd $baseDir/$workDir/$postgisSourceDir
	
	make > $baseDir/$workDir/logs/postgis_make.log 2>&1

        if [[ $? -ne 0 ]]; then
                echo "Postgis make failed, check logs ...."
                return 1
        fi

        if [[ $postgisShortVersion -ge 23 ]]; then
                echo "Adding OGR FDW to Postgis 2.3+"
                mkdir ogr && tar -xf /opt/pgbin-build/sources/ogr_fdw_v1.0.2.tar.gz --strip-components=1 -C ogr
                cd ogr
                export PATH=$buildLocation/bin:$PATH:/opt/gis-tools/gdal2/bin
		echo $PATH
		which pg_config
                USE_PGXS=1 make > $baseDir/$workDir/logs/ogr_make.log 2>&1
                if [[ $? -eq 0 ]]; then
                        make install > $baseDir/$workDir/logs/ogr_install.log 2>&1
                        if [[ $? -ne 0 ]]; then
                                echo "Failed to install OGR FDW, check logs for details ...."
                        fi
                fi

        fi


	cd $baseDir/$workDir/$postgisSourceDir
	#rm -rf $buildLocation/lib
	rm -rf $buildLocation/include
	
	make install >  $baseDir/$workDir/logs/postgis_install.log 2>&1

	if [[ $? -ne 0 ]]; then
       		echo "Failed to install Postgis, check logs .... "
	else
        	echo "Postgis built & installed successfully .... "
	fi

	copyFilesFromExtDeps

	rm -rf $buildLocation/bin/pg_config
	rm -rf $buildLocation/bin/gdal-config
	rm -rf $buildLocation/lib/postgresql/pgxs
	rm -rf $buildLocation/lib/libpgcommon.a
	rm -rf $buildLocation/lib/libpgport.a
	rm -rf $buildLocation/lib/libpostgres.a
	rm -rf $buildLocation/lib/libpq.*
	unset LD_LIBRARY_PATH
}

# This function adds the required libs to the build
function copySharedLibs {
		cp $projLib/bin/libproj-9.dll $buildLocation/bin/
		cp $geosLib/bin/libgeos_c-1.dll $buildLocation/bin/
		cp $geosLib/bin/libgeos-3-6-2.dll $buildLocation/bin/
		cp $pcreLib/bin/libpcre-1.dll $buildLocation/bin/
		cp $jsonLib/bin/libjson-c-2.dll $buildLocation/bin/
		
                cp $gdalLib/bin/libfreexl-1.dll $buildLocation/bin/
                cp $gdalLib/bin/libsqlite3-0.dll $buildLocation/bin/
#                cp /c/Windows/system32/ODBCCP32.dll $buildLocation/bin/
#                cp /c/Windows/system32/ODBC32.dll $buildLocation/bin/
#                cp $sharedLibs/$buildOS/lib/libexpat.1.dylib $buildLocation/lib/
                cp -R $gdalLib/gdal-${gdalVer}/share/* $buildLocation/share/
                cp $gdalLib/gdal-${gdalVer}/bin/* $buildLocation/bin/

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


# Creates the final bundle
function createPostGISBundle {
	cd $baseDir/$workDir
	postgisTar="postgis${postgisMajorVersion}${postgisMinorVersion}-pg`echo $pgVersion | awk -F '.' '{print $1$2}'`-$postgisFullVersion-1-win64"

	tar -cjf "$postgisTar.tar.bz2" $postgisTar >> $baseDir/$workDir/logs/tar.log 2>&1
	
	if [[ $? -ne 0 ]]; then
		echo "Unable to create tar for $PGHOME, check logs .... "
	else
		mkdir -p $archiveDir/$workDir
		mv "$postgisTar.tar.bz2" $archiveDir/$workDir/
		echo "PostGIS $postgisFullVersion packaged for PG $pgVersion ...."
	fi

	if [[ $? -eq 0 ]]; then
        	destDir=`date +%Y-%m-%d`
        	ssh build@10.0.1.118 "mkdir -p /opt/pgbin-builds/$destDir"
        	scp "$archiveDir/$workDir/$postgisTar.tar.bz2" build@10.0.1.118:/opt/pgbin-builds/$destDir/
        	exit 0
	else   
        	exit 1
	fi
}

if [[ $# -lt 1 ]]; then
	printUsage
	exit 1
fi

	while getopts "t:a:p:vh" opt; do
		case $opt in
			t)
				if [[ $OPTARG = -* ]]; then
        				((OPTIND--))
        				continue
      				fi
				postgisSourceTar=$OPTARG
				sourceTarPassed=1
				buildSpatial=1
			;;
			a)
				if [[ $OPTARG = -* ]]; then
					((OPTIND--))
				fi
				archiveDir=$OPTARG
				archiveLocationPassed=1
			;;
			p)
                                if [[ $OPTARG = -* ]]; then
                                        ((OPTIND--))
                                        continue
                                fi

				PGHOME=$OPTARG
				pgHomePassed=1
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
	echo "PostGIS Source tarball is required for the build ....."
	echo " "	
	printUsage
	exit 1
else
	
	if [[ $buildSpatial -eq 1 ]]; then 
		checkPostgisTar
		if [[ $? -eq 0 ]]; then
			buildPostgis
			if [[ $? -ne 0 ]]; then
				echo "Postgis Build failed ..."
				exit 1
			fi
		else
			echo "Can't build Postgis"
		fi
	fi 

	copySharedLibs
	#updateSharedLibPaths

	createPostGISBundle
fi
