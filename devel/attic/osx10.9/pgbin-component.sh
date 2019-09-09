#!/bin/bash
# pgbin-components.sh
# Use this script to create components/extensions for pgBin
# The script needs pgBin binaries, component source and an output dir.
# 
# Farrukh Afzal (farrukha@openscg.com)
#

#set -x
source ./versions.sh
xml2Lib="/opt/gis-tools/libxml2"
geosLib="/opt/gis-tools/geos350"
gdalLib="/opt/gis-tools/gdal-1.11.5"
projLib="/opt/gis-tools/proj4"
pcreLib="/opt/gis-tools/pcre-8.39"

baseDir="`pwd`/.."
workDir="comp`date +%Y%m%d_%H%M`"
PGHOME=""


buildNumber=1
buildOS=`uname -s`
if [[ $buildOS == "Linux" ]]; then
	buildOS="linux64";
elif [[ $buildOS == "Darwin" ]]; then
	buildOS="osx64";
elif [[ $buildOS == "MINGW64_NT-6.1" ]]; then
	buildOS="win64";
fi


buildPostGIS=false
buildPgBouncer=false
buildHadoopFDW=false
buildCassandraFDW=false
buildTSQL=false
buildTDSFDW=false
buildMySQLFDW=false
buildMongoFDW=false
buildOracleFDW=false
buildOrafce=false
componentShortVersion=""
componentFullVersion=""
buildNumber=0

postGISSource=""
slonySource=""
targetDir=""
hadoopFDWSource=""
cassandraFDWSource=""
orafceSource=""
targetDir="/opt/pgbin-build/builds"
sharedLibs="/opt/pgbin-build/pgbin/shared"
psycopgSource="/opt/pgbin-build/sources/psycopg2_2.6_osx64.tar.gz"
gdalSource="/opt/pgbin-build/sources/gdal-1.11.5.tar.gz"

# Get PG Version from the provided pgBin directory
function getPGVersion {
	if [[ ! -f "$pgBin/bin/pg_config" ]]; then
		echo "pg_config is required for building components"
		echo "No such file or firectory : $pgBin/bin/pg_config "
		exit 1	
	fi
	pgFullVersion=`$pgBin/bin/pg_config --version | awk '{print $2}'`
	echo "pgFullVersion is $pgFullVersion"

#	if [[ "${pgFullVersion/rc}" == "10devel" || "${pgFullVersion/rc}" == "10beta1" ]]; then
        if [[ "${pgFullVersion/rc}" == 10* ]]; then
		pgShortVersion="10"
	elif [[ "${pgFullVersion/rc}" == "$pgFullVersion" ]]; then
		pgShortVersion="`echo $pgFullVersion | awk -F '.' '{print $1$2}'`"
        else
                pgShortVersion="`echo $pgFullVersion | awk -F '.' '{print $1$2}'`"
                pgShortVersion="`echo ${pgShortVersion:0:2}`"
        fi

	#pgShortVersion=`echo $pgFullVersion | awk -F '.' '{print$1$2}'`
}


function prepComponentBuildDir {
	buildLocation=$1
	mkdir -p $buildLocation
	mkdir -p $buildLocation/bin
	mkdir -p $buildLocation/share
	mkdir -p $buildLocation/lib/postgresql/pgxs
	cp -r $PGHOME/include $buildLocation/
	cp -r $PGHOME/lib/postgresql/pgxs/* $buildLocation/lib/postgresql/pgxs/
	cp $PGHOME/bin/pg_config $buildLocation/bin/
	cp $PGHOME/bin/postgres $buildLocation/bin/
	cp $PGHOME/lib/libpq* $buildLocation/lib/
	cp $PGHOME/lib/libssl.* $buildLocation/lib/
	cp $PGHOME/lib/libpgport.a $buildLocation/lib/
	cp $PGHOME/lib/libpgcommon.a $buildLocation/lib/
	cp $PGHOME/lib/libcrypto.* $buildLocation/lib/
        cp $PGHOME/lib/postgresql/plpgsql.so $buildLocation/lib/postgresql/

	if [[ $buildCassandraFDW == "true" && ! ${buildLocation/cassandra} == "$buildLocation" ]]; then
		cp $sharedLibs/$buildOS/lib/libcassandra.2.dylib $buildLocation/lib/
                cp $sharedLibs/$buildOS/lib/libuv.1.dylib $buildLocation/lib/
	fi

	if [[ $buildPostGIS == "true" && ! ${buildLocation/postgis} == "$buildLocation" ]]; then
	        echo "Adding shared libs to the new build ...."
		cp $projLib/lib/libproj.9.dylib $buildLocation/lib/
                cp $geosLib/lib/libgeos_c.1.dylib $buildLocation/lib/
                cp $geosLib/lib/libgeos-3.5.0.dylib $buildLocation/lib/
                cp -R $gdalLib/lib/* $buildLocation/lib/
                cp -R $gdalLib/share/* $buildLocation/share/
                cp $gdalLib/bin/* $buildLocation/bin/
                cp $pcreLib/lib/libpcre.1.dylib $buildLocation/lib/
                ###cp $xml2Lib/lib/libxml2.2.dylib $buildLocation/lib/
                cp /usr/lib/libxml2.2.dylib $buildLocation/lib/
	fi
}

# Prepare build environment for nginx
function prepNginxBuildDir {
        buildLocation=$1
        mkdir -p $buildLocation
        mkdir -p $buildLocation/lib
	cp $pcreLib/lib/libpcre.1.dylib $buildLocation/lib/
        cp "$sharedLibs/$buildOS/lib/libz.1.dylib" $buildLocation/lib/
        cp $PGHOME/lib/libssl.* $buildLocation/lib/
        cp $PGHOME/lib/libcrypto.* $buildLocation/lib/
}

function cleanUpComponentDir {
	cd $1
	rm -rf bin/pg_config
	rm -rf bin/postgres
	rm -rf lib/postgresql/plpgsql.so
	rm -rf include
	rm -rf lib/postgresql/pgxs
	rm -rf lib/libpq*
	rm -rf lib/libssl.*
	rm -rf lib/libcrypto.*
	rm -rf lib/libpgport.a
	rm -rf lib/libpgcommon.a
	
	if [[ ! "$(ls -A bin)" ]]; then
		rm -rf bin
	fi
}

function  packageComponent {
	
	cd "$baseDir/$workDir/build/"
	tar -cjf "$componentBundle.tar.bz2" $componentBundle
	mkdir -p "$targetDir/$workDir"
	mv "$componentBundle.tar.bz2" "$targetDir/$workDir/"

}

function updateOSXSharedLibs {

	if [[ $buildPostGIS == "true" && ! ${buildLocation/postgis} == "$buildLocation" ]]; then
        	cd $buildLocation/bin
                echo "Fixing pgsql2shp"
                install_name_tool -change $(otool -L pgsql2shp | grep liblwgeom | awk '{print $1}') @executable_path/../lib/liblwgeom-2.3.0.dylib pgsql2shp
                install_name_tool -change $(otool -L pgsql2shp | grep libpq | awk '{print $1}') @executable_path/../lib/libpq.5.dylib pgsql2shp

                echo "Fixing shp2pgsql"
                install_name_tool -change $(otool -L shp2pgsql | grep liblwgeom-2.3.0.dylib | awk '{print $1}') @executable_path/../lib/liblwgeom-2.3.0.dylib shp2pgsql 

                echo "Fixing raster2pgsql"
                install_name_tool -change $(otool -L raster2pgsql | grep liblwgeom-2.3.0.dylib | awk '{print $1}') @executable_path/../lib/liblwgeom-2.3.0.dylib raster2pgsql
                install_name_tool -change $(otool -L raster2pgsql | grep libproj.9.dylib | awk '{print $1}') @executable_path/../lib/libproj.9.dylib raster2pgsql
                install_name_tool -change $(otool -L raster2pgsql | grep libgdal.1.dylib | awk '{print $1}') @executable_path/../lib/libgdal.1.dylib raster2pgsql
                install_name_tool -change $(otool -L raster2pgsql | grep libgeos_c.1.dylib | awk '{print $1}') @executable_path/../lib/libgeos_c.1.dylib raster2pgsql
                install_name_tool -change $(otool -L raster2pgsql | grep libgeos-3.5.0.dylib | awk '{print $1}') @executable_path/../lib/libgeos-3.5.0.dylib raster2pgsql
                install_name_tool -change $(otool -L raster2pgsql | grep libxml2.2.dylib | awk '{print $1}') @executable_path/../lib/libxml2.2.dylib raster2pgsql

		if [[ -f ogr_fdw_info ]]; then
			install_name_tool -change /opt/gis-tools/gdal/lib/libgdal.1.dylib @executable_path/../lib/libgdal.1.dylib ogr_fdw_info
		fi

                echo "Fixing ogr2ogr"
                install_name_tool -change $(otool -L ogr2ogr | grep libgdal.1.dylib | awk '{print $1}') @executable_path/../lib/libgdal.1.dylib ogr2ogr
                install_name_tool -change $(otool -L ogr2ogr | grep libpq | awk '{print $1}') @executable_path/../lib/libpq.5.dylib ogr2ogr

                cd $buildLocation/lib
                echo "Fixing liblwgeom"
                install_name_tool -change $(otool -L liblwgeom-2.3.0.dylib | grep libgeos_c.1.dylib | awk '{print $1}') @executable_path/../lib/libgeos_c.1.dylib liblwgeom-2.3.0.dylib
                #install_name_tool -change $(otool -L liblwgeom-2.2.5.dylib | grep libgeos-3.5.0.dylib | awk '{print $1}') @executable_path/../lib/libgeos-3.5.0.dylib liblwgeom-2.2.5.dylib
                install_name_tool -change $(otool -L liblwgeom-2.3.0.dylib | grep libproj.9.dylib | awk '{print $1}') @executable_path/../lib/libproj.9.dylib liblwgeom-2.3.0.dylib

                echo "Fixing libgeos"
                install_name_tool -change $(otool -L libgeos_c.1.dylib | grep libgeos-3.5.0.dylib | awk '{print $1}') @executable_path/../lib/libgeos-3.5.0.dylib libgeos_c.1.dylib

                echo "Fixing gdal"
                install_name_tool -change $(otool -L libgdal.1.dylib | grep libpq.5.dylib | awk '{print $1}') @executable_path/../lib/libpq.5.dylib libgdal.1.dylib

                echo "Fixing rtpostgis"
                cd $buildLocation/lib/postgresql
                install_name_tool -change $(otool -L rtpostgis-2.3.so | grep libgdal | awk '{print $1}') @executable_path/../lib/libgdal.1.dylib rtpostgis-2.3.so
                install_name_tool -change $(otool -L rtpostgis-2.3.so | grep libgeos_c.1.dylib | awk '{print $1}') @executable_path/../lib/libgeos_c.1.dylib rtpostgis-2.3.so
                install_name_tool -change $(otool -L rtpostgis-2.3.so | grep libproj.9.dylib | awk '{print $1}') @executable_path/../lib/libproj.9.dylib rtpostgis-2.3.so

                echo "Fixing postgis_topology"
                install_name_tool -change $(otool -L postgis_topology-2.3.so | grep libproj | awk '{print $1}') @executable_path/../lib/libproj.9.dylib postgis_topology-2.3.so 
                install_name_tool -change $(otool -L postgis_topology-2.3.so | grep libgeos_c | awk '{print $1}') @executable_path/../lib/libgeos_c.1.dylib postgis_topology-2.3.so

                echo "Fixing postgis.so"
                install_name_tool -change $(otool -L postgis-2.3.so | grep libgeos_c | awk '{print $1}') @executable_path/../lib/libgeos_c.1.dylib postgis-2.3.so
                install_name_tool -change $(otool -L postgis-2.3.so | grep libproj.9.dylib | awk '{print $1}') @executable_path/../lib/libproj.9.dylib postgis-2.3.so

	        echo "Fixing ogr_fdw.so"
		if [[ -f ogr_fdw.so ]]; then
        		install_name_tool -change $(otool -L ogr_fdw.so | grep libgdal | awk '{print $1}') @executable_path/../lib/libgdal.1.dylib ogr_fdw.so
		fi

                echo "Fixing address_standardizer"
                install_name_tool -change $(otool -L address_standardizer-2.3.so | grep libpcre.1.dylib | awk '{print $1}') @executable_path/../lib/libpcre.1.dylib address_standardizer-2.3.so
	fi

	if [[ $buildCassandraFDW == "true" && ! ${buildLocation/cassandra} == "$buildLocation" ]]; then
		cd $buildLocation/lib
		install_name_tool -change $(otool -L libcassandra.2.dylib | grep libuv | awk '{print $1}') "@executable_path/../lib/libuv.1.dylib" libcassandra.2.dylib >> $baseDir/$workDir/logs/libPath.log 2>&1
                install_name_tool -change $(otool -L libcassandra.2.dylib | grep libssl.1.0.0 | awk '{print $1}') "@executable_path/../lib/libssl.1.0.0.dylib" libcassandra.2.dylib >> $baseDir/$workDir/logs/libPath.log 2>&1
                install_name_tool -change $(otool -L libcassandra.2.dylib | grep libcrypto.1.0.0 | awk '{print $1}') "@executable_path/../lib/libcrypto.1.0.0.dylib" libcassandra.2.dylib >> $baseDir/$workDir/logs/libPath.log 2>&1
		cd $buildLocation/lib/postgresql
                install_name_tool -change $(otool -L cassandra_fdw.so | grep libcassandra.2.dylib | awk '{print $1}') "@executable_path/../lib/libcassandra.2.dylib" cassandra_fdw.so >> $baseDir/$workDir/logs/libPath.log 2>&1
	fi

	if [[ $buildpgRepack == "true" && ! ${buildLocation/pgrepack} == "$buildLocation" ]]; then
		cd $buildLocation/bin
		install_name_tool -change $(otool -L pg_repack | grep libpq | awk '{print $1}') "@executable_path/../lib/libpq.5.dylib" pg_repack >> $baseDir/$workDir/logs/libPath.log 2>&1
	fi

	if [[ $buildNginx == "true" && ! ${buildLocation/nginx} == "$buildLocation" ]]; then
		cd $buildLocation/sbin
		install_name_tool -change $(otool -L nginx | grep libssl.1.0.0 | awk '{print $1}') "@executable_path/../lib/libssl.1.0.0" nginx >> $baseDir/$workDir/logs/libPath.log 2>&1
		install_name_tool -change $(otool -L nginx | grep libcrypto.1.0.0 | awk '{print $1}') "@executable_path/../lib/libcrypto.1.0.0" nginx >> $baseDir/$workDir/logs/libPath.log 2>&1
		install_name_tool -change $(otool -L nginx | grep libpcre.1.dylib | awk '{print $1}') "@executable_path/../lib/libpcre.1.dylib" nginx >> $baseDir/$workDir/logs/libPath.log 2>&1
		install_name_tool -change $(otool -L nginx | grep libz.1.dylib | awk '{print $1}') "@executable_path/../lib/libz.1.dylib" nginx >> $baseDir/$workDir/logs/libPath.log 2>&1
	fi
}


function buildSlonyComponent {
	PGHOME=$pgBin
	
	mkdir -p "$baseDir/$workDir"
	cd "$baseDir/$workDir"
	mkdir slony && tar -xf $slonySource --strip-components=1 -C slony
	cd slony

	componentFullVersion=`./configure --version | head -n1 | awk '{print $3}'`
	componentShortVersion=`echo $componentFullVersion | awk -F '.' '{print$1$2}'`
	buildLocation="$baseDir/$workDir/build/slony$componentShortVersion-pg$pgShortVersion-$componentFullVersion-$slonyBuildV-$buildOS"
	
	prepComponentBuildDir $buildLocation
	
	mkdir -p "$baseDir/$workDir/logs"
	export LD_LIBRARY_PATH=$buildLocation/lib:$LD_LIBRARY_PATH
	
	./configure --with-pgconfigdir=$buildLocation/bin --disable-rpath --with-pgport LDFLAGS="-Wl,-rpath,SLONY_BIN_ORIGIN/../lib/" > "$baseDir/$workDir/logs/slony_configure.log" 2>&1
	
	if [[ $? -ne 0 ]]; then
		echo "Configure failed for slony, check logs for details."
		return 1
	fi
	make > "$baseDir/$workDir/logs/slony_make.log" 2>&1
	if [[ $? -ne 0 ]]; then
		echo "make failed for slony, check logs for details."
		return 1
	fi
	make install > "$baseDir/$workDir/logs/slony_install.log" 2>&1
	if [[ $? -ne 0 ]]; then
		echo "Install failed for slony, check logs for details."
		return 1
	fi

	
	cd $buildLocation/bin
	chrpath -r "\${ORIGIN}/../lib" * >> $baseDir/$workDir/logs/libPath.log 2>&1
        
        cd $buildLocation/lib

        
        if [[ -d "$buildLocation/lib/postgresql" ]]; then
                cd $buildLocation/lib/postgresql

             	chrpath -r "\${ORIGIN}/../../lib" * >> $baseDir/$workDir/logs/libPath.log 2>&1
                
        fi
	
	componentBundle="slony$componentShortVersion-pg$pgShortVersion-$componentFullVersion-$slonyBuildV-$buildOS"

	cleanUpComponentDir $buildLocation
	updateOSXSharedLibs
	packageComponent $componentBundle
}

function buildCassandraFDWComponent {	

	componentName="cassandra_fdw$cassandraFDWShortVersion-pg$pgShortVersion-$cassandraFDWFullVersion-$cassandraFDWBuildV-$buildOS"
	mkdir -p "$baseDir/$workDir/logs"
	cd "$baseDir/$workDir"
	mkdir cassandra_fdw && tar -xf $cassandraFDWSource --strip-components=1 -C cassandra_fdw
	cd cassandra_fdw

	buildLocation="$baseDir/$workDir/build/$componentName"

	prepComponentBuildDir $buildLocation

	PATH=$buildLocation/bin:$PATH	
	USE_PGXS=1 make > $baseDir/$workDir/logs/cassandraFDW_make.log 2>&1
	if [[ $? -eq 0 ]]; then
		 USE_PGXS=1 make install > $baseDir/$workDir/logs/cassandraFDW_install.log 2>&1
		if [[ $? -ne 0 ]]; then
			echo "Cassandra FDW install failed, check logs for details."
		fi
	else
		echo "Cassandra FDW Make failed, check logs for details."
		return 1
	fi

	componentBundle=$componentName
	cleanUpComponentDir $buildLocation
	updateOSXSharedLibs
	packageComponent $componentBundle	

}

function buildHadoopFDWComponent {	

	componentName="hadoop_fdw$hadoopFDWShortVersion-pg$pgShortVersion-$hadoopFDWFullVersion-$hadoopFDWBuildV-$buildOS"
	mkdir -p "$baseDir/$workDir/logs"
	cd "$baseDir/$workDir"
	mkdir hadoop_fdw && tar -xf $hadoopFDWSource --strip-components=1 -C hadoop_fdw
	cd hadoop_fdw

	buildLocation="$baseDir/$workDir/build/$componentName"

	prepComponentBuildDir $buildLocation

	PATH=$buildLocation/bin:$PATH	
	USE_PGXS=1 make > $baseDir/$workDir/logs/hadoopFDW_make.log 2>&1
	if [[ $? -eq 0 ]]; then
		 USE_PGXS=1 make install > $baseDir/$workDir/logs/hadoopFDW_install.log 2>&1
		if [[ $? -ne 0 ]]; then
			echo "Hadoop FDW install failed, check logs for details."
		fi
		cd $buildLocation/lib/postgresql
		jar cvf Hadoop_FDW.jar Hadoop*.class
		rm -rf *.class
	else
		echo "Hadoop FDW Make failed, check logs for details."
		return 1
	fi

	componentBundle=$componentName
	cleanUpComponentDir $buildLocation
	updateOSXSharedLibs
	packageComponent $componentBundle	

}

function buildOrafceComponent {	

	componentName="orafce$orafceShortVersion-pg$pgShortVersion-$orafceFullVersion-$orafceBuildV-$buildOS"
	mkdir -p "$baseDir/$workDir/logs"
	cd "$baseDir/$workDir"
	mkdir orafce && tar -xf $orafceSource --strip-components=1 -C orafce
	cd orafce

	buildLocation="$baseDir/$workDir/build/$componentName"

	prepComponentBuildDir $buildLocation


	PATH=$buildLocation/bin:$PATH
	USE_PGXS=1 make > $baseDir/$workDir/logs/orafce_make.log 2>&1
	if [[ $? -eq 0 ]]; then
		 USE_PGXS=1 make install > $baseDir/$workDir/logs/orafce_install.log 2>&1
		if [[ $? -ne 0 ]]; then
			echo "Orafce install failed, check logs for details."
		fi
	else
		echo "Orafce Make failed, check logs for details."
		return 1
	fi

	componentBundle=$componentName
	cleanUpComponentDir $buildLocation
	updateOSXSharedLibs
	packageComponent $componentBundle
}

function buildPgBouncerComponent {	

	componentName="orafce$orafceShortVersion-pg$pgShortVersion-$orafceFullVersion-$orafceBuildV-$buildOS"
	mkdir -p "$baseDir/$workDir/logs"
	cd "$baseDir/$workDir"
	mkdir orafce && tar -xf $orafceSource --strip-components=1 -C orafce
	cd orafce

	buildLocation="$baseDir/$workDir/build/$componentName"

	prepComponentBuildDir $buildLocation


	PATH=$buildLocation/bin:$PATH	

	USE_PGXS=1 make > $baseDir/$workDir/logs/orafce_make.log 2>&1
	if [[ $? -eq 0 ]]; then
		 USE_PGXS=1 make install > $baseDir/$workDir/logs/orafce_install.log 2>&1
		if [[ $? -ne 0 ]]; then
			echo "Orafce install failed, check logs for details."
		fi
	else
		echo "Orafce Make failed, check logs for details."
		return 1
	fi

	componentBundle=$componentName
	cleanUpComponentDir $buildLocation
	updateOSXSharedLibs
	packageComponent $componentBundle
}

function buildPostGISComponent {	

	componentName="postgis$postgisShortVersion-pg$pgShortVersion-$postgisFullVersion-$postgisBuildV-$buildOS"
	mkdir -p "$baseDir/$workDir/logs"
	cd "$baseDir/$workDir"
	mkdir postgis && tar -xf $postGISSource --strip-components=1 -C postgis


	buildLocation="$baseDir/$workDir/build/$componentName"

	prepComponentBuildDir $buildLocation

	PATH=$buildLocation/bin:$PATH
        LD_RUN_PATH=$buildLocation/lib
        export LD_LIBRARY_PATH=$sharedLibs:$buildLocation/lib

	cd postgis
        ./configure --prefix=$buildLocation --with-pgconfig=$buildLocation/bin/pg_config --with-pcredir=$pcreLib --with-geosconfig=$geosLib/bin/geos-config --with-projdir=$projLib --with-gdalconfig=$buildLocation/bin/gdal-config LDFLAGS=-Wl,-rpath,'$$ORIGIN'/../lib/ > $baseDir/$workDir/logs/postgis_configure.log 2>&1

        if [[ $? -ne 0 ]]; then
                echo "Postgis configure failed, check config.log for details ...."
                return 1
        fi

        make > $baseDir/$workDir/logs/postgis_make.log 2>&1

        if [[ $? -ne 0 ]]; then
                echo "Postgis make failed, check logs ...."
                return 1
        fi

        make install >  $baseDir/$workDir/logs/postgis_install.log 2>&1

        if [[ $? -ne 0 ]]; then
                echo "Failed to install Postgis, check logs .... "
        else
                echo "Postgis built & installed successfully .... "
        fi

        if [[ $postgisShortVersion -le 23 ]]; then
                echo "Adding OGR FDW to Postgis 2.3+"
                mkdir ogr && tar -xf /opt/pgbin-build/sources/ogr_fdw_v1.0.2.tar.gz --strip-components=1 -C ogr
                cd ogr
                export PATH=$PATH:/opt/gis-tools/gdal/bin
                USE_PGXS=1 make > $baseDir/$workDir/logs/ogr_make.log 2>&1
                if [[ $? -eq 0 ]]; then
                        make install > $baseDir/$workDir/logs/ogr_install.log 2>&1
                        if [[ $? -ne 0 ]]; then
                                echo "Failed to install OGR FDW, check logs for details ...."
                        fi
                fi

        fi


        unset LD_LIBRARY_PATH
	componentBundle=$componentName
	cleanUpComponentDir $buildLocation
	updateOSXSharedLibs
	packageComponent $componentBundle
}

function buildTDSFDWComponent {	

	componentName="tds_fdw$tdsFDWShortVersion-pg$pgShortVersion-$tdsFDWFullVersion-$tdsFDWBuildV-$buildOS"
	mkdir -p "$baseDir/$workDir/logs"
	cd "$baseDir/$workDir"
	mkdir tds_fdw && tar -xf $tdsFDWSource --strip-components=1 -C tds_fdw
	cd tds_fdw

	buildLocation="$baseDir/$workDir/build/$componentName"

	prepComponentBuildDir $buildLocation


	PATH=$buildLocation/bin:$PATH
	USE_PGXS=1 make > $baseDir/$workDir/logs/tdsfdw_make.log 2>&1
	if [[ $? -eq 0 ]]; then
		 USE_PGXS=1 make install > $baseDir/$workDir/logs/tds_install.log 2>&1
		if [[ $? -ne 0 ]]; then
			echo "TDS FDW install failed, check logs for details."
		fi
	else
		echo "TDS FDW Make failed, check logs for details."
		return 1
	fi

	componentBundle=$componentName
	cleanUpComponentDir $buildLocation
	updateOSXSharedLibs
	packageComponent $componentBundle
}

function buildTSQLComponent {	

	componentName="pgtsql$pgTSQLShortVersion-pg$pgShortVersion-$pgTSQLFullVersion-$pgTSQLBuildV-$buildOS"
	mkdir -p "$baseDir/$workDir/logs"
	cd "$baseDir/$workDir"
	mkdir pgtsql && tar -xf $tsqlSource --strip-components=1 -C pgtsql
	cd pgtsql

	buildLocation="$baseDir/$workDir/build/$componentName"

	prepComponentBuildDir $buildLocation


	PATH=$buildLocation/bin:$PATH
	USE_PGXS=1 make > $baseDir/$workDir/logs/pgtsql_make.log 2>&1
	if [[ $? -eq 0 ]]; then
		 USE_PGXS=1 make install > $baseDir/$workDir/logs/pgtsql_install.log 2>&1
		if [[ $? -ne 0 ]]; then
			echo "TSQL install failed, check logs for details."
		fi
	else
		echo "TSQL Make failed, check logs for details."
		return 1
	fi

	componentBundle=$componentName
	cleanUpComponentDir $buildLocation
	updateOSXSharedLibs
	packageComponent $componentBundle
}

function buildOracleFDWComponent {	
	export ORACLE_HOME="/opt/pgbin-build/pgbin/shared/instantclient_10_2"
	componentName="oracle_fdw$oFDWShortVersion-pg$pgShortVersion-$oFDWFullVersion-$oFDWBuildV-$buildOS"
	mkdir -p "$baseDir/$workDir/logs"
	cd "$baseDir/$workDir"
	mkdir oracle_fdw && tar -xf $oracleFDWSource --strip-components=1 -C oracle_fdw
	cd oracle_fdw

	buildLocation="$baseDir/$workDir/build/$componentName"

	prepComponentBuildDir $buildLocation


	PATH=$buildLocation/bin:$PATH
	USE_PGXS=1 make > $baseDir/$workDir/logs/oraclefdw_make.log 2>&1
	if [[ $? -eq 0 ]]; then
		 USE_PGXS=1 make install > $baseDir/$workDir/logs/oraclefdw_install.log 2>&1
		if [[ $? -ne 0 ]]; then
			echo "Oracle FDW install failed, check logs for details."
		fi
	else
		echo "Oracle FDW Make failed, check logs for details."
		return 1
	fi

	componentBundle=$componentName
	cleanUpComponentDir $buildLocation
	updateOSXSharedLibs
	packageComponent $componentBundle
}

function buildPGAuditComponent {	

	componentName="pgaudit$pgAuditShortVersion-pg$pgShortVersion-$pgAuditFullVersion-$pgAuditBuildV-$buildOS"
	mkdir -p "$baseDir/$workDir/logs"
	cd "$baseDir/$workDir"
	mkdir pgaudit && tar -xf $pgAuditSource --strip-components=1 -C pgaudit
	cd pgaudit

	buildLocation="$baseDir/$workDir/build/$componentName"

	prepComponentBuildDir $buildLocation


	PATH=$buildLocation/bin:$PATH
	USE_PGXS=1 make > $baseDir/$workDir/logs/pgaudit_make.log 2>&1
	if [[ $? -eq 0 ]]; then
		 USE_PGXS=1 make install > $baseDir/$workDir/logs/pgaudit_install.log 2>&1
		if [[ $? -ne 0 ]]; then
			echo "pgAudit install failed, check logs for details."
		fi
	else
		echo "pgAudit Make failed, check logs for details."
		return 1
	fi

	componentBundle=$componentName
	cleanUpComponentDir $buildLocation
	updateOSXSharedLibs
	packageComponent $componentBundle
}

function buildSetUserComponent {	

	componentName="setuser$setUserShortVersion-pg$pgShortVersion-$setUserFullVersion-$setUserBuildV-$buildOS"
	mkdir -p "$baseDir/$workDir/logs"
	cd "$baseDir/$workDir"
	mkdir setuser && tar -xf $setUserSource --strip-components=1 -C setuser
	cd setuser

	buildLocation="$baseDir/$workDir/build/$componentName"

	prepComponentBuildDir $buildLocation

	PATH=$buildLocation/bin:$PATH
	USE_PGXS=1 make > $baseDir/$workDir/logs/setuser_make.log 2>&1
	if [[ $? -eq 0 ]]; then
		 USE_PGXS=1 make install > $baseDir/$workDir/logs/setuser_install.log 2>&1
		if [[ $? -ne 0 ]]; then
			echo "SetUser install failed, check logs for details."
		fi
	else
		echo "SetUser Make failed, check logs for details."
		return 1
	fi

	componentBundle=$componentName
	cleanUpComponentDir $buildLocation
	updateOSXSharedLibs
	packageComponent $componentBundle
}

function buildPLDebuggerComponent {

        componentName="pldebugger$plDebugShortVersion-pg$pgShortVersion-$plDebugFullVersion-$plDebugBuildV-$buildOS"
        mkdir -p "$baseDir/$workDir/logs"
        cd "$baseDir/$workDir"
        mkdir pldebugger && tar -xf $plDebugSource --strip-components=1 -C pldebugger
        cd pldebugger

        buildLocation="$baseDir/$workDir/build/$componentName"

        prepComponentBuildDir $buildLocation


        PATH=$buildLocation/bin:$PATH
        USE_PGXS=1 make > $baseDir/$workDir/logs/pldebugger_make.log 2>&1
        if [[ $? -eq 0 ]]; then
                 USE_PGXS=1 make install > $baseDir/$workDir/logs/pldebugger_install.log 2>&1
                if [[ $? -ne 0 ]]; then
                        echo "plDebugger install failed, check logs for details."
                fi
        else
                echo "plDebugger Make failed, check logs for details."
                return 1
        fi

        componentBundle=$componentName
        cleanUpComponentDir $buildLocation
	updateOSXSharedLibs
        packageComponent $componentBundle
}

function buildPGPartmanComponent {

        componentName="pgpartman$pgPartmanShortVersion-pg$pgShortVersion-$pgPartmanFullVersion-$pgPartmanBuildV-$buildOS"
        mkdir -p "$baseDir/$workDir/logs"
        cd "$baseDir/$workDir"
        mkdir pgpartman && tar -xf $pgpartmanSource --strip-components=1 -C pgpartman
        cd pgpartman

        buildLocation="$baseDir/$workDir/build/$componentName"

        prepComponentBuildDir $buildLocation


        PATH=$buildLocation/bin:$PATH
        USE_PGXS=1 make > $baseDir/$workDir/logs/pgpartman_make.log 2>&1
        if [[ $? -eq 0 ]]; then
                 USE_PGXS=1 make install > $baseDir/$workDir/logs/pgpartman_install.log 2>&1
                if [[ $? -ne 0 ]]; then
                        echo "pg_partman install failed, check logs for details."
                fi
        else
                echo "pg_partman Make failed, check logs for details."
                return 1
        fi

        componentBundle=$componentName
        cleanUpComponentDir $buildLocation
	updateOSXSharedLibs
        packageComponent $componentBundle
}

function buildMySQLFDWComponent {	

	componentName="mysql_fdw$mysqlFDWShortVersion-pg$pgShortVersion-$mysqlFDWFullVersion-$mysqlFDWBuildV-$buildOS"
	mkdir -p "$baseDir/$workDir/logs"
	cd "$baseDir/$workDir"
	mkdir mysql_fdw && tar -xf $mysqlFDWSource --strip-components=1 -C mysql_fdw
	cd mysql_fdw

	buildLocation="$baseDir/$workDir/build/$componentName"

	prepComponentBuildDir $buildLocation

	PATH=$buildLocation/bin:/opt/pgbin-build/pgbin/shared/linux_64/mysql/bin:$PATH
	USE_PGXS=1 make > $baseDir/$workDir/logs/mysqlfdw_make.log 2>&1
	if [[ $? -eq 0 ]]; then
		 USE_PGXS=1 make install > $baseDir/$workDir/logs/mysqlfdw_install.log 2>&1
		if [[ $? -ne 0 ]]; then
			echo "MySQL FDW install failed, check logs for details."
		fi
	else
		echo "MySQL FDW Make failed, check logs for details."
		return 1
	fi

	componentBundle=$componentName
	cleanUpComponentDir $buildLocation
	updateOSXSharedLibs
	packageComponent $componentBundle
}

function buildPlRComponent {	

	componentName="plr$plRShortVersion-pg$pgShortVersion-$plRFullVersion-$plRBuildV-$buildOS"
	mkdir -p "$baseDir/$workDir/logs"
	cd "$baseDir/$workDir"
	mkdir plr && tar -xf $plrSource --strip-components=1 -C plr
	cd plr

	buildLocation="$baseDir/$workDir/build/$componentName"

	prepComponentBuildDir $buildLocation
	export R_HOME=/opt/pgbin-build/pgbin/shared/linux_64/R323/lib64/R
	PATH=$buildLocation/bin:$PATH
	USE_PGXS=1 make > $baseDir/$workDir/logs/plr_make.log 2>&1
	if [[ $? -eq 0 ]]; then
		 USE_PGXS=1 make install > $baseDir/$workDir/logs/plr_install.log 2>&1
		if [[ $? -ne 0 ]]; then
			echo "PL/R install failed, check logs for details."
		fi
	else
		echo "PL/R Make failed, check logs for details."
		return 1
	fi

	componentBundle=$componentName
	cleanUpComponentDir $buildLocation
	updateOSXSharedLibs
	packageComponent $componentBundle
}

function buildPlJavaComponent {	

	componentName="pljava$plJavaShortVersion-pg$pgShortVersion-$plJavaFullVersion-$plJavaBuildV-$buildOS"
	mkdir -p "$baseDir/$workDir/logs"
	cd "$baseDir/$workDir"
	mkdir pljava && tar -xf $plJavaSource --strip-components=1 -C pljava
	cd pljava

	buildLocation="$baseDir/$workDir/build/$componentName"

	prepComponentBuildDir $buildLocation

	PATH=/opt/pgbin-build/pgbin/shared/osx64/maven/bin:$buildLocation/bin:$PATH
	mvn clean install > $baseDir/$workDir/logs/pljava_make.log 2>&1
	if [[ $? -eq 0 ]]; then
		java -jar "pljava-packaging/target/pljava-pg`echo $pgFullVersion | awk -F '.' '{print $1"."$2}'`-x86_64-MacOSX-gpp.jar" > $baseDir/$workDir/logs/pljava_install.log 2>&1 > $baseDir/$workDir/logs/pljava_install.log 2>&1
		if [[ $? -ne 0 ]]; then
			echo "Pl/Java install failed, check logs for details."
		fi
	else
                echo "Pl/Java Make failed, check logs for details."
                return 1

	fi

	componentBundle=$componentName
	cleanUpComponentDir $buildLocation
	updateOSXSharedLibs
	packageComponent $componentBundle
}

function buildPlV8Component {	

	componentName="plv8$plV8ShortVersion-pg$pgShortVersion-$plV8FullVersion-$plV8BuildV-$buildOS"
	mkdir -p "$baseDir/$workDir/logs"
	cd "$baseDir/$workDir"
	mkdir plv8 && tar -xf $plV8Source --strip-components=1 -C plv8
	cd plv8

	buildLocation="$baseDir/$workDir/build/$componentName"

	prepComponentBuildDir $buildLocation

	PATH=$buildLocation/bin:$PATH
        tar -xf /opt/pgbin-build/sources/v8_153_depenedencies.tar.gz 
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
	componentBundle=$componentName
	cleanUpComponentDir $buildLocation
	updateOSXSharedLibs
	packageComponent $componentBundle
}

function buildPlProfilerComponent {

        componentName="plprofiler$plProfilerShortVersion-pg$pgShortVersion-$plProfilerFullVersion-$plprofilerBuildV-$buildOS"
        mkdir -p "$baseDir/$workDir/logs"
        cd "$baseDir/$workDir"
        mkdir plprofiler && tar -xf $plProfilerSource --strip-components=1 -C plprofiler
        cd plprofiler

        buildLocation="$baseDir/$workDir/build/$componentName"

        prepComponentBuildDir $buildLocation

        PATH=$buildLocation/bin:$PATH
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
        componentBundle=$componentName
        cleanUpComponentDir $buildLocation
	updateOSXSharedLibs
        packageComponent $componentBundle
}

function buildBulkLoadComponent {

        componentName="bulkload$bulkLoadShortVersion-pg$pgShortVersion-$bulkLoadFullVersion-$bulkLoadBuildV-$buildOS"
        mkdir -p "$baseDir/$workDir/logs"
        cd "$baseDir/$workDir"
        mkdir bulk_load && tar -xf $bulkLoadSource --strip-components=1 -C bulk_load
        cd bulk_load

        buildLocation="$baseDir/$workDir/build/$componentName"

        prepComponentBuildDir $buildLocation


        PATH=$buildLocation/bin:$PATH
        USE_PGXS=1 make > $baseDir/$workDir/logs/bulkload_make.log 2>&1
        if [[ $? -eq 0 ]]; then
                 USE_PGXS=1 make install > $baseDir/$workDir/logs/bulkload_install.log 2>&1
                if [[ $? -ne 0 ]]; then
                        echo "BulkLoad install failed, check logs for details."
                fi
        else
                echo "BulkLoad Make failed, check logs for details."
                return 1
        fi

        componentBundle=$componentName
        cleanUpComponentDir $buildLocation
        updateOSXSharedLibs
        packageComponent $componentBundle
}

function buildpgRepackComponent {

        componentName="repack$pgrepackShortVersion-pg$pgShortVersion-$pgrepackFullVersion-$pgrepackBuildV-$buildOS"
        mkdir -p "$baseDir/$workDir/logs"
        cd "$baseDir/$workDir"
        mkdir pgrepack && tar -xf $pgrepackSource --strip-components=1 -C pgrepack
        cd pgrepack

        buildLocation="$baseDir/$workDir/build/$componentName"

        prepComponentBuildDir $buildLocation


        PATH=$buildLocation/bin:$PATH
        USE_PGXS=1 make > $baseDir/$workDir/logs/pgrepack_make.log 2>&1
        if [[ $? -eq 0 ]]; then
                 USE_PGXS=1 make install > $baseDir/$workDir/logs/pgrepack_install.log 2>&1
                if [[ $? -ne 0 ]]; then
                        echo "pgRepack install failed, check logs for details."
                fi
        else
                echo "pgRepack Make failed, check logs for details."
                return 1
        fi

        componentBundle=$componentName
        cleanUpComponentDir $buildLocation
        updateOSXSharedLibs
        packageComponent $componentBundle
}

function buildpgLogicalComponent {

        componentName="logical$pgLogicalShortVersion-pg$pgShortVersion-$pgLogicalFullVersion-$pgLogicalBuildV-$buildOS"
        mkdir -p "$baseDir/$workDir/logs"
        cd "$baseDir/$workDir"
        mkdir pglogical && tar -xf $pgLogicalSource --strip-components=1 -C pglogical
        cd pglogical

        buildLocation="$baseDir/$workDir/build/$componentName"

        prepComponentBuildDir $buildLocation


        PATH=$buildLocation/bin:$PATH
        USE_PGXS=1 make > $baseDir/$workDir/logs/pglogical_make.log 2>&1
        if [[ $? -eq 0 ]]; then
                 USE_PGXS=1 make install > $baseDir/$workDir/logs/pglogical_install.log 2>&1
                if [[ $? -ne 0 ]]; then
                        echo "pgLogical install failed, check logs for details."
                fi
        else
                echo "pgLogical Make failed, check logs for details."
                return 1
        fi

        componentBundle=$componentName
        cleanUpComponentDir $buildLocation
        updateOSXSharedLibs
        packageComponent $componentBundle
}

function buildNginxComponent {

        componentName="nginx-$nginxFullVersion-$nginxBuildV-$buildOS"
        mkdir -p "$baseDir/$workDir/logs"
        cd "$baseDir/$workDir"
        mkdir nginx && tar -xf $nginxSource --strip-components=1 -C nginx
        cd nginx

        buildLocation="$baseDir/$workDir/build/$componentName"

        prepNginxBuildDir $buildLocation


        PATH=$buildLocation/bin:$PATH
        #./auto/configure --prefix=$buildLocation --with-pcre=$pcreLib --with-zlib=$sharedLibs/$buildOS > $baseDir/$workDir/logs/nginx_configure.log 2>&1
        ./auto/configure --prefix=$buildLocation --with-http_ssl_module --with-cc-opt="-I$pcreLib/include -I$sharedLibs/$buildOS/include" --with-ld-opt="-L$pcreLib/lib -L$sharedLibs/$buildOS/lib -Wl,-rpath,'$\${ORIGIN}'/../lib/" > $baseDir/$workDir/logs/nginx_configure.log 2>&1
        make > $baseDir/$workDir/logs/nginx_make.log 2>&1
        if [[ $? -eq 0 ]]; then
                make install > $baseDir/$workDir/logs/nginx_install.log 2>&1
                if [[ $? -ne 0 ]]; then
                        echo "nginx install failed, check logs for details."
                fi
        else
                echo "nginx Make failed, check logs for details."
                return 1
        fi

        componentBundle=$componentName
        updateOSXSharedLibs
        packageComponent $componentBundle
}

function buildPGHintPlanComponent {

        componentName="hintplan-pg$pgShortVersion-$hintplanFullVersion-$hintplanBuildV-$buildOS"
        mkdir -p "$baseDir/$workDir/logs"
        cd "$baseDir/$workDir"
        mkdir pghintplan && tar -xf $pgHintplanSource --strip-components=1 -C pghintplan
        cd pghintplan

        buildLocation="$baseDir/$workDir/build/$componentName"

        prepComponentBuildDir $buildLocation


        PATH=$buildLocation/bin:$PATH
        USE_PGXS=1 make > $baseDir/$workDir/logs/pghintplan_make.log 2>&1
        if [[ $? -eq 0 ]]; then
                 USE_PGXS=1 make install > $baseDir/$workDir/logs/pghintplan_install.log 2>&1
                if [[ $? -ne 0 ]]; then
                        echo "pgHintplan install failed, check logs for details."
                fi
        else
                echo "pgHintplan Make failed, check logs for details."
                return 1
        fi

        componentBundle=$componentName
        cleanUpComponentDir $buildLocation
        updateSharedLibs
        packageComponent $componentBundle
}

TEMP=`getopt -l with-pgbin:,build-slony:,build-postgis:,build-pgbouncer:,build-hadoop-fdw:,build-cassandra-fdw:,build-pgtsql:,build-tds-fdw:,build-mongo-fdw:,build-mysql-fdw:,build-oracle-fdw:,build-orafce:,build-pgaudit:,build-set-user:,build-pgpartman:,build-pldebugger:,build-plr:,build-pljava:,build-plv8:,build-plprofiler:,build-bulkload:,build-pglogical:,build-pgrepack:,build-nginx:,build-hintplan:,build-number: -- "$@"`

if [ $? != 0 ] ; then
	echo "Required parameters missing, Terminating..."
	exit 1
fi

#eval set -- "$TEMP"

while true; do
  case "$1" in
    --with-pgbin ) pgBinPassed=true; pgBin=$2; shift; shift; ;;
    --target-dir ) targetDirPassed=true; targetDir=$2; shift; shift; ;;
    --build-postgis ) buildPostGIS=true; postGISSource=$2;shift; shift ;;
    --build-pgbouncer ) buildPgBouncer=$2; shift; shift; ;;
    --build-hadoop-fdw ) buildHadoopFDW=true; hadoopFDWSource=$2; shift; shift ;;
    --build-cassandra-fdw ) buildCassandraFDW=true; cassandraFDWSource=$2; shift; shift ;;
    --build-pgtsql ) buildTSQL=true; tsqlSource=$2; shift; shift ;;
    --build-tds-fdw ) buildTDSFDW=true; tdsFDWSource=$2; shift; shift ;;
    --build-mongo-fdw ) buildMongoFDW=true mongoFDWSource=$2; shift; shift ;;
    --build-mysql-fdw ) buildMySQLFDW=true; mysqlFDWSource=$2; shift; shift ;;
    --build-oracle-fdw ) buildOracleFDW=true; oracleFDWSource=$2; shift; shift ;;
    --build-orafce ) buildOrafce=true; orafceSource=$2; shift; shift ;;
    --build-pgaudit ) buildPGAudit=true; pgAuditSource=$2; shift; shift ;;
    --build-set-user ) buildSetUser=true; setUserSource=$2; shift; shift ;;
    --build-pldebugger ) buildPLDebugger=true; plDebugSource=$2; shift; shift ;;
    --build-pgpartman ) buildPGPartman=true; pgpartmanSource=$2; shift; shift ;;
    --build-slony ) buildSlony=true; slonySource=$2; shift; shift ;;
    --build-plr ) buildPlr=true; plrSource=$2; shift; shift ;;
    --build-plv8 ) buildPlV8=true; plV8Source=$2; shift; shift ;;
    --build-pljava ) buildPlJava=true; plJavaSource=$2; shift; shift ;;
    --build-plprofiler ) buildPlProfiler=true; plProfilerSource=$2; shift; shift ;;
    --build-bulkload ) buildBulkLoad=true; bulkLoadSource=$2; shift; shift ;;
    --build-pgrepack ) buildpgRepack=true; pgrepackSource=$2; shift; shift ;;
    --build-pglogical ) buildpgLogical=true; pgLogicalSource=$2; shift; shift ;;
    --build-nginx ) buildNginx=true; nginxSource=$2; shift; shift ;;
    --build-hintplan ) buildPGHintPlan=true; pgHintplanSource=$2; shift; shift ;;
    --build-number ) buildNumber=$2; shift; shift ;;
    -- ) shift; break ;;
    -* ) echo "Invalid Option Passed"; exit 1; ;;
    * ) break ;;
  esac
done

if [[ $pgBinPassed != "true" ]]; then
	echo "Please provide a valid PostgreSQL version to build ..."
	exit 1
fi

getPGVersion

echo "Platform : $buildOS"
echo "Add Postgis : $buildPostGIS"
echo "Add pgBouncer : $buildPgBouncer"
echo "Add Hadoop FDW : $buildHadoopFDW"
echo "Add Cassandra FDW : $buildCassandraFDW"
echo "Add pgTSQL : $buildTSQL"
echo "Add MongoFDW : $buildMongoFDW"
echo "Add MySQL FDW : $buildMySQLFDW"
echo "Add Oracle FDW : $buildOracleFDW"
echo "Add Orafce : $buildOrafce"
echo "Add PGAudit : $buildPGAudit"
echo "Add Set-User : $buildSetUser"
echo "pgBin : $pgFullVersion"
echo "buildNumber : $buildNumber"

PGHOME=$pgBin


if [[ $buildSlony == "true" ]]; then
	buildSlonyComponent
fi

if [[ $buildCassandraFDW == "true" ]]; then
	buildCassandraFDWComponent
fi

if [[ $buildHadoopFDW == "true" ]]; then
	buildHadoopFDWComponent
fi

if [[ $buildOrafce == "true" ]]; then
	buildOrafceComponent
fi

if [[ $buildPostGIS == "true" ]]; then
	buildPostGISComponent
fi

if [[ $buildTDSFDW == "true" ]]; then
	buildTDSFDWComponent
fi

if [[ $buildOracleFDW == "true" ]]; then
	buildOracleFDWComponent
fi

if [[ $buildPGAudit == "true" ]]; then
	buildPGAuditComponent
fi

if [[ $buildSetUser == "true" ]]; then
	buildSetUserComponent
fi

if [[ $buildPLDebugger == "true" ]]; then
	buildPLDebuggerComponent
fi

if [[ $buildPGPartman == "true" ]]; then
        buildPGPartmanComponent
fi

if [[ $buildMySQLFDW == "true" ]]; then
	buildMySQLFDWComponent
fi

if [[ $buildPlr == "true" ]]; then
	buildPlRComponent
fi

if [[ $buildPlJava == "true" ]]; then
	buildPlJavaComponent
fi

if [[ $buildPlV8 == "true" ]]; then
	buildPlV8Component
fi
if [[ $buildTSQL == "true" ]]; then
        buildTSQLComponent
fi
if [[ $buildPlProfiler == "true" ]]; then
        buildPlProfilerComponent
fi
if [[ $buildBulkLoad == "true" ]]; then
        buildBulkLoadComponent
fi
if [[ $buildpgRepack == "true" ]]; then
        buildpgRepackComponent
fi
if [[ $buildpgLogical == "true" ]]; then
        buildpgLogicalComponent
fi
if [[ $buildNginx == "true" ]]; then
        buildNginxComponent
fi
if [[ $buildPGHintPlan == "true" ]]; then
        buildPGHintPlanComponent
fi
#updateOSXSharedLibs

echo $componentBundle

destDir=`date +%Y-%m-%d`
ssh build@10.0.1.118 "mkdir -p /opt/pgbin-builds/$destDir"
scp $targetDir/$workDir/$componentBundle.tar.bz2 build@10.0.1.118:/opt/pgbin-builds/$destDir/
