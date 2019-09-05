cur_dir=`pwd`

cd $OUT
pyver=`python --version  > /dev/null 2>&1`
rc=$?
echo rc=$rc
if [ $rc == 0 ];then
  python -m SimpleHTTPServer &
else
  python3 -m http.server &
fi

cd $cur_dir
