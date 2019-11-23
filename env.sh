
#----------------------------------------------------------------#
#      Copyright (c) 2015-2019 BigSQL, all rights reserved      #
#----------------------------------------------------------------#

hubV=5.0.3

P12=12.1-1
P11=11.6-1

anonV=0.5.0-1
ddlxV=0.15-1
omniV=2.16-1
hypoV=1.1.3-1
timescaleV=1.5.1-1
logicalV=2.3.0-1
profV=4.1-1
tsqlV=3.0-1

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
