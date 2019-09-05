#!/bin/bash

source ./env.sh
rc=$?
if [ ! "$rc" == "0" ]; then
  echo "YIKES - no env.sh found"
  exit 1
fi;


buildALL () {
  bigV=$1
  fullV=$2
  echo ""
  echo "################## BUILD_ALL $bigV $fullV ###################"

  buildONE l64 $bigV $fullV $lin
}


buildONE () {
  vPlat=$1
  vBig=$2
  vFull=$3

  if [ "$4" == "false" ]; then
    return
  fi
  parms="-X $vPlat -c bigsql -N $vFull -p $vBig -Bb"
  echo ""
  echo "### BUILD_ONE $parms ###"
  ./build.sh $parms
  rc=`echo $?`
  if [ $rc -ne 0 ]; then
    exit $rc
  fi
}

is11=true

echo "############### Build Package Managers ##################"
rm -f $OUT/hub-$hubV*
rm -f $OUT/bigsql-pgc-$hubV*
./build.sh -X posix   -c bigsql-pgc -N $hubV

if [ "$is11" == "true" ]; then
  buildALL 11 $P11
fi;

echo ""
exit 0
