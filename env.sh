
#----------------------------------------------------------------#
#      Copyright (c) 2015-2019 BigSQL, all rights reserved      #
#----------------------------------------------------------------#

hubV=5.0.3

P12=12.1-3
P11=11.6-3

profV=4.1-1

HUB="$PWD"
SRC="$HUB/src"
zipOut="off"
isENABLED=false

pg="postgres"

OS=`uname -s`
if [[ $OS == "Linux" ]]; then
  OS=linux64;
  outDir=l64
fi

plat=$OS
