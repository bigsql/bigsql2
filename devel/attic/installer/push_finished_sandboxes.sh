#/bin/sh

source env.sh

#pgver=($P96b)

pgver=($P11b $P10b $P96b $P95b $P94b)

#pgver=($P96b)

cd /home/build/pginstaller/output
##cleanup app folders if not already removed
rm -rf *.app

        for i in "${pgver[@]}"

        do
                echo "##Upload WIN64 Installer Version $i to $mirror##"

                        scp -p PostgreSQL-$i-win64-bigsql.exe $mirror:/data/pgc/out/

                echo "##Verifying Win64 Installer Version $i has copied sucessfully##"

                        diff <(sha512sum $buildPATH/pginstaller/output/PostgreSQL-$i-win64-bigsql.exe | awk -F'/' '{print $1}') <(ssh $mirror "sha512sum /data/pgc/out/PostgreSQL-$i-win64-bigsql.exe" | awk -F'/' '{print $1}')

                                if [[ $? -ne 0 ]]; then
                                        echo "***WIN64 Version $i INSTALLER VERIFICATION FAILED***"
                                        break
                                else
                                        echo "***WIN64 Version $i INSTALLER VERIFICATION SUCEEDED***"
                                fi

                echo "##Upload OSX64 Installer Version $i to $mirror##"

                        scp -p PostgreSQL-$i-osx64-bigsql.dmg $mirror:/data/pgc/out/

                echo "##Verifying OSX64 Installer Version $i has copied sucessfully##"

                        diff <(sha512sum $buildPATH/pginstaller/output/PostgreSQL-$i-osx64-bigsql.dmg | awk -F'/' '{print $1}') <(ssh $mirror "sha512sum /data/pgc/out/PostgreSQL-$i-osx64-bigsql.dmg" | awk -F'/' '{print $1}')

                                if [[ $? -ne 0 ]]; then
                                        echo "***OSX64 Version $i INSTALLER VERIFICATION FAILED***"
                                        break
                                else
                                        echo "***OSX64 Version $i INSTALLER VERIFICATION SUCEEDED***"
                                fi

        done
