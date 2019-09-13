#!/bin/bash

source ./env.sh
rc=$?
if [ ! "$rc" == "0" ]; then
  echo "YIKES - no env.sh found"
  exit 1
fi;

majorV="$1"
if [ "$majorV" == "11" ]; then
  minorV=$P11
elif [ "$majorV" == "12" ]; then
  minorV=$P12
else
  echo "ERROR: must supply pg version of 11 or 12"
  exit 1
fi


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


echo "############### Build Package Managers ##################"
rm -f $OUT/hub-$hubV*
rm -f $OUT/bigsql-pgc-$hubV*
./build.sh -X posix   -c bigsql-pgc -N $hubV

buildALL $majorV $minorV

echo ""
exit 0
