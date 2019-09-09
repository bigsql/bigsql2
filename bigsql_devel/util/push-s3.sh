
cmd="aws --region us-east-1 s3 sync . s3://bigsql"

$cmd $1
rc=$?

exit $rc

