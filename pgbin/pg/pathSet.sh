if [ $# -lt 1 ]; then
  echo "illegal number of parameters"
  return 1
fi
pgHome="$PWD/$1"
if ! [ -d "$pgHome" ]; then
  echo "Invalid PGHOME"
  return 1
fi

export PGHOME=$pgHome
export PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin
export PATH=$PGHOME/bin:$PATH

echo "# PGHOME = $PGHOME"
echo "#   PATH = $PATH"
echo "# Success!"
cd $1/contrib
pwd
