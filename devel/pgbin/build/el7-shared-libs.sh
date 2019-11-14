shared_lib=/opt/pgbin-build/pgbin/shared/linux_64/lib/
mkdir -p $shared_lib

cp -v /usr/lib64/libreadline.so.6 $shared_lib/.
cp -v /usr/lib64/libtermcap.so $shared_lib/libtermcap.so.2
cp -v /usr/lib64/libz.so.1 $shared_lib/.
cp -v /usr/lib64/libssl.so.1.0.2k $shared_lib/libssl.so.1.0.0
cp -v /usr/lib64/libcrypto.so.1.0.2k $shared_lib/libcrypto.so.1.0.0
cp -v /usr/lib64/libk5crypto.so.3.1 $shared_lib/libk5crypto.so.3
cp -v /usr/lib64/libkrb5support.so.0.1 $shared_lib/libkrb5support.so.0
cp -v /usr/lib64/libkrb5.so.3 $shared_lib/.
cp -v /usr/lib64/libcom_err.so.2.1 $shared_lib/libcom_err.so.3
cp -v /usr/lib64/libgssapi_krb5.so.2.2 $shared_lib/libgssapi_krb5.so.2
cp -v /usr/lib64/libxslt.so.1 $shared_lib/.
cp -v /usr/lib64/libldap-2.4.so.2 $shared_lib/.
cp -v /usr/lib64/libldap_r-2.4.so.2 $shared_lib/.
cp -v /usr/lib64/liblber-2.4.so.2 $shared_lib/.
cp -v /usr/lib64/libsasl2.so.3 $shared_lib/.
cp -v /usr/lib64/libuuid.so.1.3.0 $shared_lib/libuuid.so.16
cp -v /usr/lib64/libxml2.so.2.9.1 $shared_lib/libxml2.so
cp -v /usr/lib64/libevent-2.0.so.5.1.9 $shared_lib/libevent-2.0.so.5
