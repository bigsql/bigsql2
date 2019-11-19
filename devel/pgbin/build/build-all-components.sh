
source versions.sh


function build {
  bin11="--with-pgbin /opt/pgcomponent/pg11"
  echo ""
  echo "###################################"
  echo "$1 $2"
  ./build-component.sh --build-$1 $SRC/$1-$2.tar.gz $bin11
  rc=$?
}


################### MAINLINE #####################

if [ "$1" == "pgtsql" ] || [ "$1" == "all" ]; then
  build pgtsql $pgTSQLFullV
fi

if [ "$1" == "plprofiler" ] || [ "$1" == "all" ]; then
  build plprofiler $plProfilerFullVersion
fi

if [ "$1" == "cassandra_fdw" ] || [ "$1" == "all" ]; then
  build cassandra_fdw $cassandraFDWFullVersion
fi

if [ "$1" == "timescaledb" ] || [ "$1" == "all" ]; then
  build timescaledb $timescaledbFullV
fi

if [ "$1" == "pglogical" ] || [ "$1" == "all" ]; then
  build pglogical $pgLogicalFullV
fi

if [ "$1" == "anon" ] || [ "$1" == "all" ]; then
  build anon $anonFullV
fi

if [ "$1" == "ddlx" ] || [ "$1" == "all" ]; then
  build ddlx $ddlxFullV
fi

exit 0
