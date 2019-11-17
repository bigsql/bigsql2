
#----------------------------------------------------------------#
#      Copyright (c) 2015-2019 BigSQL, all rights reserved      #
#----------------------------------------------------------------#

hubV=5.0.3

P12=12.1-1
P11=11.6-1
P10=10.11-1

anonV=0.5.0-1
ddlxV=0.15-1
omniV=2.16-1
timescaleV=1.5.1-1
logicalV=2.3.0-1
#spockV=2.3.1-1
profV=4.1-1
cstarV=3.1.4-1
athenafdwV=3.1-2
tsqlV=3.0beta1-1
patroniV=1.6.0
saltV=2019pp
pipV=19pp

HUB="$PWD"
SRC="$HUB/src"
zipOut="off"
isENABLED=false

pg="postgres"

OS=`uname -s`
if [[ $OS == "Darwin" ]]; then
  OS=osx64;
  outDir=m64
elif [[ $OS == "MINGW64_NT-6.1" ]]; then
  OS=win64;
  outDir=w64
elif [[ $OS == "Linux" ]]; then
  grep "CPU architecture:" /proc/cpuinfo 1>/dev/null
  rc=$?
  if [ "$rc" == "0" ]; then
    OS=arm64
    outDir=a64
  else
    OS=linux64;
    outDir=l64
  fi
fi

plat=$OS
