
source bp.sh
./apg install pg11; ./apg start pg11 -y -d demo; ./apg status
./apg install pglogical -d demo; ./apg status
./apg install plprofiler -d demo; ./apg status
./apg install timescaledb -d demo; ./apg status

