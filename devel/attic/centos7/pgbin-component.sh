#!/bin/bash

echo ""
echo "######################### pgbin-component.sh ######################"
# 
# Use this script to create components/extensions for pgBin
# The script needs pgBin binaries, component source and an output dir.
#

#set -x
source ./versions.sh
xml2Lib="/opt/gis-tools/libxml2"
geosLib="/opt/gis-tools/geos-3.6.2"
gdalLib="/opt/pgbin-build/pgbin/shared/linux_64/gdal"
projLib="/opt/gis-tools/proj4"
pcreLib="/opt/gis-tools/pcre-8.39"
jsonLib="/opt/gis-tools/json-c"

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

componentShortVersion=""
componentFullVersion=""
buildNumber=0

targetDir="/opt/pgbin-build/build"
sharedLibs="/opt/pgbin-build/pgbin/shared"

# Get PG Version from the provided pgBin directory
function getPGVersion {
	if [[ ! -f "$pgBin/bin/pg_config" ]]; then
		echo "pg_config is required for building components"
		echo "No such file or firectory : $pgBin/bin/pg_config "
		return 1
	fi
	pgFullVersion=`$pgBin/bin/pg_config --version | awk '{print $2}'`

        if [[ "${pgFullVersion/rc}" =~ 12.* ]]; then
                pgShortVersion="12"
        elif [[ "${pgFullVersion/rc}" =~ 11.* ]]; then
                pgShortVersion="11"
        elif [[ "${pgFullVersion/rc}" =~ 10.* ]]; then
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
	cp $PGHOME/lib/libpq* $buildLocation/lib/
	cp $PGHOME/lib/libssl.so* $buildLocation/lib/
	cp $PGHOME/lib/libpgport.a $buildLocation/lib/
	cp $PGHOME/lib/libpgcommon.a $buildLocation/lib/
	cp $PGHOME/lib/libcrypto.so* $buildLocation/lib/
        cp $PGHOME/lib/postgresql/plpgsql.so $buildLocation/lib/postgresql/

	if [[ $buildCassandraFDW == "true" && ! ${buildLocation/cassandra} == "$buildLocation" ]]; then
		cp "$sharedLibs/$buildOS/lib/libcassandra.so.2" $buildLocation/lib/
		cp "$sharedLibs/$buildOS/lib/libuv.so.1" $buildLocation/lib/
	fi

	if [[ $buildPostGIS == "true" && ! ${buildLocation/postgis} == "$buildLocation" ]]; then
	        cp $projLib/lib/libproj.so.9 $buildLocation/lib/
	        cp $geosLib/lib/libgeos_c.so.1 $buildLocation/lib/
	        cp $geosLib/lib/libgeos-3.6.2.so $buildLocation/lib/
                cp $sharedLibs/$buildOS/lib/libfreexl.so.1 $buildLocation/lib/
                cp $sharedLibs/$buildOS/lib/libsqlite3.so.0 $buildLocation/lib/
                cp $sharedLibs/$buildOS/lib/libodbc.so.2 $buildLocation/lib/
                cp $sharedLibs/$buildOS/lib/libodbcinst.so.2 $buildLocation/lib/
                cp $sharedLibs/$buildOS/lib/libcurl.so.4 $buildLocation/lib/
                cp $sharedLibs/$buildOS/lib/libexpat.so.1 $buildLocation/lib/
                cp -R $gdalLib/lib/* $buildLocation/lib/
                cp -R $gdalLib/share/* $buildLocation/share/
                cp $gdalLib/bin/* $buildLocation/bin/
	        cp $xml2Lib/lib/libxml2.so.2 $buildLocation/lib/
                cp $pcreLib/lib/libpcre.so.1 $buildLocation/lib/
                cp $jsonLib/lib/libjson-c.so.2 $buildLocation/lib/
	fi

	if [[ $buildTDSFDW == "true" && ! ${buildLocation/tds} == "$buildLocation" ]]; then
		cp "$sharedLibs/$buildOS/lib/libsybdb.so.5" $buildLocation/lib/
		cp "$sharedLibs/$buildOS/bin/tsql" $buildLocation/bin/
	fi
	
	if [[ $buildCstoreFDW == "true" && ! ${buildLocation/cstore} == "$buildLocation" ]]; then
		cp "$sharedLibs/$buildOS/lib/libprotobuf-c.so.0" $buildLocation/lib/
	fi

	if [[ $buildPlr == "true" && ! ${buildLocation/plr} == "$buildLocation" ]]; then
		cp "$sharedLibs/$buildOS/R323/lib64/R/lib/libR.so" $buildLocation/lib/
		cp "$sharedLibs/$buildOS/R323/lib64/R/lib/libRblas.so" $buildLocation/lib/
	fi

        if [[ $buildPGCollectd == "true" && ! ${buildLocation/collectd} == "$buildLocation" ]]; then
        	cp $PGHOME/lib/libgssapi_krb5.so.2 $buildLocation/lib/
        	cp $PGHOME/lib/libldap_r-2.4.so.2 $buildLocation/lib/
        	cp $PGHOME/lib/libkrb5.so.3 $buildLocation/lib/
        	cp $PGHOME/lib/libk5crypto.so.3 $buildLocation/lib/
        	cp $PGHOME/lib/libcom_err.so.3 $buildLocation/lib/
        	cp $PGHOME/lib/libkrb5support.so.0 $buildLocation/lib/
        	cp $PGHOME/lib/liblber-2.4.so.2 $buildLocation/lib/
        	cp $PGHOME/lib/libsasl2.so.3 $buildLocation/lib/
		cp /usr/lib64/libltdl.so.7 $buildLocation/lib/
        fi
}


function cleanUpComponentDir {
	cd $1
	rm -rf bin/pg_config
	rm -rf lib/postgresql/plpgsql.so
	rm -rf include
	rm -rf lib/postgresql/pgxs
	if [[ $buildPGCollectd == "false" ]]; then
		rm -rf lib/libpq*
		rm -rf lib/libssl.*
		rm -rf lib/libcrypto.*
	fi
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
	echo "# outDir = $targetDir/$workDir"

}

# For postgis - Copy files from external dependencies. For example
# Files from $projLib/share/proj should be copied to share/postgresql/contrib/postgis-2.4/proj
function copyFilesFromExtDeps {
        if [[ $buildPostGIS == "true" && ! ${buildLocation/postgis} == "$buildLocation" ]]; then
                cd $buildLocation/share/postgresql/contrib/postgis-2.4
                mkdir proj
                cp $projLib/share/proj/* proj/
        fi
}

function updateSharedLibs {

	if [[ -d bin ]]; then
		cd $buildLocation/bin
		for file in `dir -d *` ; do
			chrpath -r "\${ORIGIN}/../lib" "$file" >> $baseDir/$workDir/logs/libPath.log 2>&1
        	done
        fi

        cd $buildLocation/lib
	for file in `dir -d *so*` ; do
                chrpath -r "\${ORIGIN}/../lib" "$file" >> $baseDir/$workDir/logs/libPath.log 2>&1
        done

        if [[ -d "$buildLocation/lib/postgresql" ]]; then
                cd $buildLocation/lib/postgresql
		for file in `dir -d *so*` ; do
             		chrpath -r "\${ORIGIN}/../../lib" "$file" >> $baseDir/$workDir/logs/libPath.log 2>&1
		done
        fi


        if [[ $buildPGCollectd == "true" && ! ${buildLocation/collectd} == "$buildLocation" ]]; then
                cd $buildLocation/lib/collectd
                chrpath -r "\${ORIGIN}/../../lib" "postgresql.so" >> $baseDir/$workDir/logs/libPath.log 2>&1
		cd $buildLocation/sbin
		for file in `dir -d *` ; do
			chrpath -r "\${ORIGIN}/../lib" "$file" >> $baseDir/$workDir/logs/libPath.log 2>&1
		done
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
	updateSharedLibs
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
	updateSharedLibs
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
	updateSharedLibs
	packageComponent $componentBundle
}

function buildPgBouncerComponent {

	componentName="bouncer$bouncerShortVersion-pg$pgShortVersion-$bouncerFullVersion-$bouncerBuildV-$buildOS"
	mkdir -p "$baseDir/$workDir/logs"
	cd "$baseDir/$workDir"
	mkdir bouncer && tar -xf $bouncerSource --strip-components=1 -C bouncer
	cd bouncer

	buildLocation="$baseDir/$workDir/build/$componentName"

	prepComponentBuildDir $buildLocation


	PATH=$buildLocation/bin:$PATH

	USE_PGXS=1 make > $baseDir/$workDir/logs/bouncer_make.log 2>&1
	if [[ $? -eq 0 ]]; then
		 USE_PGXS=1 make install > $baseDir/$workDir/logs/bouncer_install.log 2>&1
		if [[ $? -ne 0 ]]; then
			echo "pgBouncer install failed, check logs for details."
		fi
	else
		echo "pgBouncer Make failed, check logs for details."
		return 1
	fi

	componentBundle=$componentName
	cleanUpComponentDir $buildLocation
	updateSharedLibs
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
        ./configure --prefix=$buildLocation --with-pgconfig=$buildLocation/bin/pg_config --with-pcredir=$pcreLib --with-geosconfig=$geosLib/bin/geos-config --with-projdir=$projLib --with-jsondir=$jsonLib --with-xml2config=$xml2Lib/bin/xml2-config --with-gdalconfig=$gdalLib/bin/gdal-config LDFLAGS=-Wl,-rpath,'$$ORIGIN'/../lib/ > $baseDir/$workDir/logs/postgis_configure.log 2>&1

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

	if [[ $postgisShortVersion -le 24 ]]; then
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
	updateSharedLibs
	copyFilesFromExtDeps
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
	updateSharedLibs
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
	updateSharedLibs
	packageComponent $componentBundle
}

function buildOracleFDWComponent {

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
	updateSharedLibs
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
	updateSharedLibs
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
	updateSharedLibs
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
        packageComponent $componentBundle
}


function buildComp {
	comp="$1"
        echo "#        comp: $comp"
        shortV="$2"
        echo "#      shortV: $shortV"
        fullV="$3"
        echo "#       fullV: $fullV"
        buildV="$4"
        echo "#      buildV: $buildV"
        src="$5"
        echo "#         src: $src"

        componentName="$comp$shortV-pg$pgShortVersion-$fullV-$buildV-$buildOS"
        echo "#      compNm: $componentName"
        mkdir -p "$baseDir/$workDir/logs"
        cd "$baseDir/$workDir"
        mkdir $comp  && tar -xf $src --strip-components=1 -C $comp
        cd $comp

        buildLocation="$baseDir/$workDir/build/$componentName"

        prepComponentBuildDir $buildLocation


        PATH=$buildLocation/bin:$PATH
        log_dir="$baseDir/$workDir/logs"
        echo "#     log_dir: $log_dir"
        make_log="$log_dir/$comp-make.log"
        echo "#    make_log: $make_log"
        install_log="$log_dir/$comp-install.log"
        echo "# install_log: $install_log"

        if [ "$comp" == "bdr_plugin" ]; then
           echo "Building BDR Plugin"
           ./autogen.sh
           ./configure
        fi

        if [ "$comp" == "athena_fdw" ]; then
           buildLib=$buildLocation/lib
           ln -s $JAVA_HOME/jre/lib/amd64/server/libjvm.so $buildLib/libjvm.so
        fi

        USE_PGXS=1 make > $make_log 2>&1
        if [[ $? -eq 0 ]]; then
                USE_PGXS=1 make install > $install_log 2>&1
                if [[ $? -ne 0 ]]; then
                        echo " "
                        echo "ERROR: Install failed, check install_log"
                        #tail -10 $install_log
                        echo ""
                fi
        else
                echo " "
                echo "ERROR: Make failed, check make_log"
                echo " "
                #tail -10 $make_log
                return 1
        fi

        componentBundle=$componentName
        cleanUpComponentDir $buildLocation
        updateSharedLibs
        packageComponent $componentBundle
	echo "#########################################################"
}


function buildPGAgentComponent {

        componentName="pgagent$pgAgentShortVersion-pg$pgShortVersion-$pgAgentFullVersion-$pgAgentBuildV-$buildOS"
        mkdir -p "$baseDir/$workDir/logs"
        cd "$baseDir/$workDir"
        mkdir pgagent  && tar -xf $pgAgentSource --strip-components=1 -C pgagent
        cd pgagent

        buildLocation="$baseDir/$workDir/build/$componentName"

        prepComponentBuildDir $buildLocation


        PATH=$buildLocation/bin:$PATH
        log_dir="$baseDir/$workDir/logs"
        make_log="$log_dir/pgagent_make.log"
        install_log="$log_dir/pgagent_install.log"
        ls -l
        ccmake .
        USE_PGXS=1 make > $make_log 2>&1
        if [[ $? -eq 0 ]]; then
                USE_PGXS=1 make install > $install_log 2>&1
                if [[ $? -ne 0 ]]; then
                        echo " "
                        echo "pgagent install failed, check logs for details."
                        cat $install_log
                        echo ""
                fi
        else
                echo " "
                echo "pgagent Make failed, check logs for details."
                echo " "
                cat $make_log
                return 1
        fi

        componentBundle=$componentName
        cleanUpComponentDir $buildLocation
        packageComponent $componentBundle
}


function buildCronComponent {

        componentName="cron$cronShortVersion-pg$pgShortVersion-$cronFullVersion-$cronBuildV-$buildOS"
        mkdir -p "$baseDir/$workDir/logs"
        cd "$baseDir/$workDir"
        mkdir cron  && tar -xf $cronSource --strip-components=1 -C cron
        cd cron

        buildLocation="$baseDir/$workDir/build/$componentName"

        prepComponentBuildDir $buildLocation


        PATH=$buildLocation/bin:$PATH
        USE_PGXS=1 make > $baseDir/$workDir/logs/cron_make.log 2>&1
        if [[ $? -eq 0 ]]; then
                 USE_PGXS=1 make install > $baseDir/$workDir/logs/cron_install.log 2>&1
                if [[ $? -ne 0 ]]; then
                        echo "cron install failed, check logs for details."
                fi
        else
                echo "cron Make failed, check logs for details."
                return 1
        fi

        componentBundle=$componentName
        cleanUpComponentDir $buildLocation
        updateSharedLibs
        packageComponent $componentBundle
}


function buildPgMpComponent {

        componentName="pgmp$pgmpShortVersion-pg$pgShortVersion-$pgmpFullVersion-$pgmpBuildV-$buildOS"
        mkdir -p "$baseDir/$workDir/logs"
        cd "$baseDir/$workDir"
        mkdir pgmp  && tar -xf $pgmpSource --strip-components=1 -C pgmp
        cd pgmp

        buildLocation="$baseDir/$workDir/build/$componentName"

        prepComponentBuildDir $buildLocation


        PATH=$buildLocation/bin:$PATH
        make > $baseDir/$workDir/logs/pgmp_make.log 2>&1
        if [[ $? -eq 0 ]]; then
                make docs    > $baseDir/$workDir/logs/pgmp_docs.log 2>&1
                if [[ $? -ne 0 ]]; then
                        echo "pgmp docs failed, check logs for details."
                fi
        else
                echo "pgmp Make failed, check logs for details."
                return 1
        fi
        if [[ $? -eq 0 ]]; then
                make install > $baseDir/$workDir/logs/pgmp_install.log 2>&1
                if [[ $? -ne 0 ]]; then
                        echo "pgmp install failed, check logs for details."
                fi
        else
                echo "pgmp Make failed, check logs for details."
                return 1
        fi

        componentBundle=$componentName
        cleanUpComponentDir $buildLocation
        updateSharedLibs
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
	updateSharedLibs
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
			echo "MySQL FDW install failed, check logs for details."
		fi
	else
		echo "MySQL FDW Make failed, check logs for details."
		return 1
	fi

	componentBundle=$componentName
	cleanUpComponentDir $buildLocation
	updateSharedLibs
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

	PATH=/opt/pgbin-build/pgbin/shared/maven/bin:$buildLocation/bin:$PATH
	mvn clean install > $baseDir/$workDir/logs/pljava_make.log 2>&1
	if [[ $? -eq 0 ]]; then
		java -jar "pljava-packaging/target/pljava-pg`echo $pgFullVersion | awk -F '.' '{print $1"."$2}'`-amd64-Linux-gpp.jar" > $baseDir/$workDir/logs/pljava_install.log 2>&1 > $baseDir/$workDir/logs/pljava_install.log 2>&1
		if [[ $? -ne 0 ]]; then
			echo "Pl/Java install failed, check logs for details."
		fi
	else
                mkdir -p pljava-packaging/target
                cp "/tmp/pljava-pg`echo $pgFullVersion | awk -F '.' '{print $1}'`-amd64-Linux-gpp.jar" pljava-packaging/target/
                java -jar "pljava-packaging/target/pljava-pg`echo $pgFullVersion | awk -F '.' '{print $1}'`-amd64-Linux-gpp.jar" > $baseDir/$workDir/logs/pljava_install.log 2>&1
                #echo "Pl/Java Make failed, check logs for details."
                #return 1
	fi

	componentBundle=$componentName
	cleanUpComponentDir $buildLocation
	updateSharedLibs
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
	componentBundle=$componentName
	cleanUpComponentDir $buildLocation
	updateSharedLibs
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
        	#cp plprofiler-bin.py $buildLocation/bin/plprofiler
        	cd $buildLocation/python/site-packages
        	#tar -xf $psycopgSource
        else
        	echo "Make failed for PlProfiler .... "
        fi
        rm -rf build
	componentBundle=$componentName
	cleanUpComponentDir $buildLocation
	updateSharedLibs
	packageComponent $componentBundle
}

function buildBackgroundComponent {

        componentName="background$backgroundShortVersion-pg$pgShortVersion-$backgroundFullVersion-$backgroundBuildV-$buildOS"
        mkdir -p "$baseDir/$workDir/logs"
        cd "$baseDir/$workDir"
        mkdir background && tar -xf $backgroundSource --strip-components=1 -C background
        cd background

        buildLocation="$baseDir/$workDir/build/$componentName"

        prepComponentBuildDir $buildLocation


        PATH=$buildLocation/bin:$PATH
        USE_PGXS=1 make > $baseDir/$workDir/logs/background_make.log 2>&1
        if [[ $? -eq 0 ]]; then
                 USE_PGXS=1 make install > $baseDir/$workDir/logs/background_install.log 2>&1
                if [[ $? -ne 0 ]]; then
                        echo "Background install failed, check logs for details."
                fi
        else
                echo "Background Make failed, check logs for details."
                return 1
        fi

        componentBundle=$componentName
        cleanUpComponentDir $buildLocation
        updateSharedLibs
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
        updateSharedLibs
        packageComponent $componentBundle
}

function buildCstoreFDWComponent {

        componentName="cstore_fdw$cstoreFDWShortVersion-pg$pgShortVersion-$cstoreFDWFullVersion-$cstoreFDWBuildV-$buildOS"
        mkdir -p "$baseDir/$workDir/logs"
        cd "$baseDir/$workDir"
        mkdir cstore_fdw && tar -xf $cstoreFDWSource --strip-components=1 -C cstore_fdw
        cd cstore_fdw

        buildLocation="$baseDir/$workDir/build/$componentName"

        prepComponentBuildDir $buildLocation


        PATH=$buildLocation/bin:$PATH:/opt/pgbin-build/pgbin/shared/linux_64/bin
        make_log=$baseDir/$workDir/logs/cstore_make.log
        USE_PGXS=1 make > $make_log 2>&1
        if [[ $? -eq 0 ]]; then
                 USE_PGXS=1 make install > $baseDir/$workDir/logs/cstore_install.log 2>&1
                if [[ $? -ne 0 ]]; then
                        echo "CSTORE FDW install failed, check logs for details."
                fi
        else
                echo "CSTORE FDW Make failed, check logs for details."
                cat $make_log
                return 1
        fi

        componentBundle=$componentName
        cleanUpComponentDir $buildLocation
        updateSharedLibs
        packageComponent $componentBundle
}

function buildParquetFDWComponent {

        componentName="parquet_fdw$parquetFDWShortVersion-pg$pgShortVersion-$parquetFDWFullVersion-$parquetFDWBuildV-$buildOS"
        echo " $componentName"
        mkdir -p "$baseDir/$workDir/logs"
        cd "$baseDir/$workDir"
        mkdir parquet_fdw && tar -xf $parquetFDWSource --strip-components=1 -C parquet_fdw
        cd parquet_fdw

        buildLocation="$baseDir/$workDir/build/$componentName"

        prepComponentBuildDir $buildLocation


        PATH=$buildLocation/bin:$PATH:/opt/pgbin-build/pgbin/shared/linux_64/bin
        make_log=$baseDir/$workDir/logs/parquet_make.log
        USE_PGXS=1 make > $make_log 2>&1
        if [[ $? -eq 0 ]]; then
                 USE_PGXS=1 make install > $baseDir/$workDir/logs/parquet_install.log 2>&1
                if [[ $? -ne 0 ]]; then
                        echo "PARQUET FDW install failed, check logs for details."
                fi
        else
                echo "PARQUET FDW Make failed, check logs for details."
                cat $make_log
                return 1
        fi

        componentBundle=$componentName
        cleanUpComponentDir $buildLocation
        updateSharedLibs
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
        updateSharedLibs
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
        updateSharedLibs
        packageComponent $componentBundle
}

function buildPGCollectdComponent {

        componentName="collectd$pgCollectdShortVersion-$pgCollectdFullVersion-$pgCollectdBuildV-$buildOS"
        mkdir -p "$baseDir/$workDir/logs"
        cd "$baseDir/$workDir"
        mkdir pgcollectd && tar -xf $pgCollectdSource --strip-components=1 -C pgcollectd
        cd pgcollectd

        buildLocation="$baseDir/$workDir/build/$componentName"

        prepComponentBuildDir $buildLocation


        PATH=$buildLocation/bin:$PATH
        export LD_LIBRARY_PATH=$buildLocation/lib:$LD_LIBRARY_PATH
	export LDFLAGS="-Wl,-rpath,$sharedLibs"
	./build.sh --enable-all-plugins
	#make distclean > $baseDir/$workDir/logs/pgcollectd_clean.log 2>&1
        #./configure --prefix=$buildLocation --datarootdir=/tmp --with-libpq=$buildLocation > $baseDir/$workDir/logs/pgcollectd_configure.log 2>&1
        ./configure --prefix=$buildLocation --with-libpq=$buildLocation > $baseDir/$workDir/logs/pgcollectd_configure.log 2>&1
        make > $baseDir/$workDir/logs/pgcollectd_make.log 2>&1
        if [[ $? -eq 0 ]]; then
                 make install > $baseDir/$workDir/logs/pgcollectd_install.log 2>&1
                if [[ $? -ne 0 ]]; then
                        echo "pgCollectd install failed, check logs for details."
                fi
        else
                echo "pgCollectd Make failed, check logs for details."
                return 1
        fi

        unset LD_LIBRARY_PATH
        componentBundle=$componentName
        cleanUpComponentDir $buildLocation
        updateSharedLibs
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
        USE_PGXS=1 make -d > $baseDir/$workDir/logs/pghintplan_make.log 2>&1
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

function buildTimeScaleDBComponent {

        componentName="apache_timescaledb-pg$pgShortVersion-$timescaledbFullVersion-$timescaledbBuildV-$buildOS"
        mkdir -p "$baseDir/$workDir/logs"
        cd "$baseDir/$workDir"
        pwd
        mkdir apache_timescaledb && tar -xf $timescaleDBSource --strip-components=1 -C apache_timescaledb
        cd apache_timescaledb

        echo "buildLocation=$baseDir/$workDir/build/$componentName"
        buildLocation="$baseDir/$workDir/build/$componentName"

        prepComponentBuildDir $buildLocation


        PATH=/opt/pgbin-build/pgbin/bin:$buildLocation/bin:$PATH

	./bootstrap -DAPACHE_ONLY=1 > $baseDir/$workDir/logs/apache_timescaledb_bootstrap.log 2>&1

	cd build
        USE_PGXS=1 make -d > $baseDir/$workDir/logs/apache_timescaledb_make.log 2>&1
        if [[ $? -eq 0 ]]; then
                 USE_PGXS=1 make install > $baseDir/$workDir/logs/apache_timescaledb_install.log 2>&1
                if [[ $? -ne 0 ]]; then
                        echo "apache_timescaledb install failed, check logs for details."
                fi
        else
                echo "apache_timescaledb Make failed, check logs for details."
                return 1
        fi

        componentBundle=$componentName
        cleanUpComponentDir $buildLocation
        updateSharedLibs
        packageComponent $componentBundle
}

TEMP=`getopt -l with-pgbin:,build-slony:,build-postgis:,build-pgbouncer:,build-athena-fdw:,build-cassandra-fdw:,build-pgtsql:,build-tds-fdw:,build-mongo-fdw:,build-mysql-fdw:,build-oracle-fdw:,build-orafce:,build-pgaudit:,build-set-user:,build-pgpartman:,build-pldebugger:,build-plr:,build-pljava:,build-plv8:,build-plprofiler:,build-background:,build-bulkload:,build-cstore-fdw:,build-parquet-fdw:,build-pgrepack:,build-pglogical:,build-collectd:,build-hintplan:,build-timescaledb:,build-pgagent:,build-cron:build-pgmp:,build-fixeddecimal:,build-number: -- "$@"`

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
    --build-bouncer ) buildBouncer=true; Source=$2; shift; shift; ;;
    --build-athena ) buildAthena=true; Source=$2; shift; shift ;;
    --build-cassandra-fdw ) buildCassandraFDW=true; cassandraFDWSource=$2; shift; shift ;;
    --build-pgtsql ) buildTSQL=true; tsqlSource=$2; shift; shift ;;
    --build-tds-fdw ) buildTDSFDW=true; tdsFDWSource=$2; shift; shift ;;
    --build-mongo-fdw ) buildMongoFDW=true mongoFDWSource=$2; shift; shift ;;
    --build-mysql-fdw ) buildMySQLFDW=true; mysqlFDWSource=$2; shift; shift ;;
    --build-oracle-fdw ) buildOracleFDW=true; oracleFDWSource=$2; shift; shift ;;
    --build-orafce ) buildOrafce=true; orafceSource=$2; shift; shift ;;
    --build-pgaudit ) buildPGAudit=true; pgAuditSource=$2; shift; shift ;;
    --build-set-user ) buildSetUser=true; setUserSource=$2; shift; shift ;;
    --build-pldebugger ) buildPLDebugger=true; Source=$2; shift; shift ;;
    --build-bdrplugin ) buildBdrPlugin=true; Source=$2; shift; shift ;;
    --build-pgpartman ) buildPGPartman=true; pgpartmanSource=$2; shift; shift ;;
    --build-slony ) buildSlony=true; slonySource=$2; shift; shift ;;
    --build-plr ) buildPlr=true; plrSource=$2; shift; shift ;;
    --build-plv8 ) buildPlV8=true; plV8Source=$2; shift; shift ;;
    --build-pljava ) buildPlJava=true; plJavaSource=$2; shift; shift ;;
    --build-plprofiler ) buildPlProfiler=true; plProfilerSource=$2; shift; shift ;;
    --build-background ) buildBackground=true; backgroundSource=$2; shift; shift ;;
    --build-bulkload ) buildBulkLoad=true; bulkLoadSource=$2; shift; shift ;;
    --build-cstore-fdw ) buildCstoreFDW=true; cstoreFDWSource=$2; shift; shift ;;
    --build-parquet-fdw ) buildParquetFDW=true; parquetFDWSource=$2; shift; shift ;;
    --build-pgrepack ) buildpgRepack=true; pgrepackSource=$2; shift; shift ;;
    --build-pglogical ) buildpgLogical=true; pgLogicalSource=$2; shift; shift ;;
    --build-collectd ) buildPGCollectd=true; pgCollectdSource=$2; shift; shift ;;
    --build-hintplan ) buildPGHintPlan=true; pgHintplanSource=$2; shift; shift ;;
    --build-timescaledb ) buildTimeScaleDB=true; timescaleDBSource=$2; shift; shift ;;
    --build-pgagent ) buildPGAgent=true; pgAgentSource=$2; shift; shift ;;
    --build-cron ) buildCron=true; cronSource=$2; shift; shift ;;
    --build-pgmp ) buildPgMp=true; pgmpSource=$2; shift; shift ;;
    --build-fixeddecimal ) buildFD=true; Source=$2; shift; shift ;;
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
echo "#       pgBin: $pgBin"

getPGVersion

PGHOME=$pgBin


if [[ $buildSlony == "true" ]]; then
	echo "Building Slony"
	buildSlonyComponent
fi

if [[ $buildCassandraFDW == "true" ]]; then
	buildCassandraFDWComponent
fi

if [[ $buildAthena == "true" ]]; then
	buildComp athena_fdw "$athenaShortV" "$athenaFullV" "$athenaBuildV" "$Source"
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
	buildComp pldebugger  "$debugShortV" "$debugFullV" "$debugBuildV" "$Source"
fi

if [[ $buildBdrPlugin  == "true" ]]; then
	buildComp bdr_plugin  "$bdrShortV" "$bdrFullV" "$bdrBuildV" "$Source"
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
if [[ $buildBackground == "true" ]]; then
        buildBackgroundComponent
fi
if [[ $buildBulkLoad == "true" ]]; then
	buildBulkLoadComponent
fi
if [[ $buildCstoreFDW == "true" ]]; then
	buildCstoreFDWComponent
fi
if [[ $buildParquetFDW == "true" ]]; then
	buildParquetFDWComponent
fi
if [[ $buildpgRepack == "true" ]]; then
	buildpgRepackComponent
fi
if [[ $buildpgLogical == "true" ]]; then
	buildpgLogicalComponent
fi
if [[ $buildPGCollectd == "true" ]]; then
        buildPGCollectdComponent
fi
if [[ $buildPGHintPlan == "true" ]]; then
        buildPGHintPlanComponent
fi
if [[ $buildTimeScaleDB == "true" ]]; then
        buildTimeScaleDBComponent
fi
if [[ $buildPGAgent == "true" ]]; then
        buildPGAgentComponent
fi
if [[ $buildCron == "true" ]]; then
        buildCronComponent
fi
if [[ $buildPgMp == "true" ]]; then
        buildPgMpComponent
fi
if [[ $buildBouncer == "true" ]]; then
        buildComp bouncer      "$ShortV"   "$fullV"   "$BuildV"   "$Source"
fi
if [[ $buildFD == "true" ]]; then
	buildComp fixeddecimal "$fdShortV" "$fdFullV" "$fdBuildV" "$Source"
fi

destDir=`date +%Y-%m-%d`
fullDestDir=/opt/pgbin-builds/$destDir
#ssh build@$pgcentral "mkdir -p $fullDestDir"
#scp $targetDir/$workDir/$componentBundle.tar.bz2 build@$pgcentral:$fullDestDir/

echo Goodbye!
exit 0

