
source bp.sh
./pgc install pg11; ./pgc start pg11 -y -d demo; ./pgc status
./pgc install pglogical -d demo; ./pgc status
./pgc install plprofiler -d demo; ./pgc status
./pgc install timescaledb -d demo; ./pgc status

