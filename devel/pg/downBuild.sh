v96=9.6.15
v10=10.10
v11=11.5
v12=12beta3

fatalError () {
  echo "FATAL ERROR!  $1"
  if [ "$2" == "u" ]; then
    printUsageMessage
  fi
  echo
  exit 1
}


echoCmd () {
  echo "# $1"
  checkCmd "$1"
}


checkCmd () {
  $1
  rc=`echo $?`
  if [ ! "$rc" == "0" ]; then
    fatalError "Stopping Script"
  fi
}


downBuild () {
  echo " "
  echo "##################### PostgreSQL $1 ###########################"
  echoCmd "rm -rf *$1*"
  echoCmd "wget https://ftp.postgresql.org/pub/source/v$1/postgresql-$1.tar.gz"
  
  if [ ! -d src ]; then
    mkdir src
  fi
  echoCmd "cp postgresql-$1.tar.gz src/."

  echoCmd "tar -xf postgresql-$1.tar.gz"
  echoCmd "mv postgresql-$1 $1"
  echoCmd "rm postgresql-$1.tar.gz"
  echoCmd "cd $1"
  echoCmd "./configure --prefix=$PWD --with-openssl"
  echoCmd "make -j5"
  echoCmd "make install"
  echoCmd "cd .."
}


#################################################################################
##                        MAINLINE
#################################################################################
#downBuild $v96
#downBuild $v10
downBuild $v11
#downBuild $v12
 
