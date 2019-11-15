
source versions.sh

bin11="--with-pgbin /opt/pgcomponent/pg11"
bld="./build-component.sh"

$bld --build-pgtsql $SRC/pgtsql-$pgTSQLFullV.tar.gz $bin11

$bld --build-timescaledb $SRC/timescaledb-$timescaledbFullV.tar.gz $bin11
