
echo "########## Build POSIX Sandbox ##########"

outp="out/posix"

if [ -d $outp ]; then
  echo "Removing current '$outp' directory..."
  $outp/pgc stop
  sleep 2
  rm -rf $outp
fi

./build.sh -X posix -R

cd $outp

./pgc set GLOBAL REPO http://localhost:8000

./pgc --version

