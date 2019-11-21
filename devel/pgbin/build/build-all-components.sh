
source versions.sh


function build {
  pgbin="--with-pgbin /opt/pgcomponent/pg$pgV"
  echo ""
  echo "###################################"
  ./build-component.sh --build-$1 $SRC/$1-$2.tar.gz $pgbin $3
  rc=$?
}


################### MAINLINE #####################

pgV="$2"
if [ ! "$pgV"  == "11" ] && [ ! "$pgV"  == "12" ]; then
  echo  "ERROR: second parm must be 11 or 12"
  exit 1
fi

if [ "$1" == "hypopg" ] || [ "$1" == "all" ]; then
  build hypopg $hypopgFullV $2 hypopg
fi

if [ "$1" == "pgtsql" ] || [ "$1" == "all" ]; then
  build pgtsql $pgTSQLFullV $2 tsql
fi

if [ "$1" == "plprofiler" ] || [ "$1" == "all" ]; then
  build plprofiler $plProfilerFullVersion $2 profiler
fi

##if [ "$1" == "cassandra_fdw" ] || [ "$1" == "all" ]; then
##  build cassandra_fdw $cassandraFDWFullVersion
##fi

if [ "$1" == "timescaledb" ] || [ "$1" == "all" ]; then
  build timescaledb $timescaledbFullV $2 timescale
fi

if [ "$1" == "pglogical" ] || [ "$1" == "all" ]; then
  build pglogical $pgLogicalFullV $2 pglogical
fi

if [ "$1" == "anon" ] || [ "$1" == "all" ]; then
  build anon $anonFullV $2 anon
fi

if [ "$1" == "ddlx" ] || [ "$1" == "all" ]; then
  build ddlx $ddlxFullV $2 ddlx
fi

exit 0
