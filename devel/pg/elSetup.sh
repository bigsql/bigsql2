
sudo yum -y update

sudo yum -y groupinstall 'Development Tools'

YUM="sudo yum -y install"

$YUM bison-devel readline-devel zlib-devel openssl-devel
$YUM libxml2-devel libxslt-devel wget openjade 
$YUM pam-devel openldap-devel uuid-devel 

$YUM llvm-devel clang-devel protobuf-c-devel 

$YUM docbook-dtds docbook-style-dsssl docbook-style-xsl
$YUM perl-ExtUtils-Embed libevent-devel postgresql-devel mkdocs highlight

