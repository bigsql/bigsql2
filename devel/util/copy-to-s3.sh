copyToS3 () {
  region="$1"
  bucket="$2"
  exclude="$3"

  flags="--acl public-read --storage-class REDUCED_REDUNDANCY --recursive"

  cmd="aws --region $region s3 cp . s3://$bucket $flags"

  if [ "$exclude" == "" ]; then
    $cmd
  else
    $cmd --exclude "$exclude/*"
  fi
  rc=$?

  echo ""
}


## MAINLINE ##################################################
if [ $# -ne 1 ]; then
  echo "ERROR: missing dir parameter"
  exit
fi

newOutDir=apg_history/$1

if [ ! -d $newOutDir ]; then
  echo "ERROR: bad dir"
  exit
fi

cd $newOutDir

if [ -d packages ]; then
  echo "Packages directory found"
  cd packages
  ls -l
  # copyToS3 "us-east-1" "oscg_download/packages" ""
  cd ..
  #exit 0
else
  echo "Packages directory not found"
  echo ""
fi

copyToS3 "us-east-1" "pgcentral" "packages"

exit 0

