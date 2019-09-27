
sudo yum -y update

sudo yum -y groupinstall 'Development Tools'

YUM="sudo yum -y install"

$YUM python3

$YUM bison-devel readline-devel zlib-devel openssl-devel
$YUM libxml2-devel libxslt-devel sqlite-devel wget openjade 
$YUM pam-devel openldap-devel uuid-devel

$YUM llvm-toolset chrpath protobuf-c

$YUM docbook-dtds docbook-style-xsl highlight
sudo pip3 install mkdocs

$YUM perl-ExtUtils-Embed libevent-devel tcl-devel postgresql-devel

