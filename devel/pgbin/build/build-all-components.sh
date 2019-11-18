
source versions.sh


function build {
  bin11="--with-pgbin /opt/pgcomponent/pg11"
  echo "$1 $2"
  ./build-component.sh --build-$1 $SRC/$1-$2.tar.gz $bin11
  rc=$?
}


################### MAINLINE #####################

if [ "$1" == "pgtsql" ] || [ "$1" == "all" ]; then
  build pgtsql $pgTSQLFullV
fi

if [ "$1" == "timescaledb" ] || [ "$1" == "all" ]; then
  build timescaledb $timescaledbFullV
fi

if [ "$1" == "pglogical" ] || [ "$1" == "all" ]; then
  build pglogical $pgLogicalFullV
fi

exit 0
