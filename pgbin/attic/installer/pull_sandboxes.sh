#/bin/sh

source env.sh

#pgver=($P10b $P96b $P95b $P94b $P93b $P92b)

#pgver=($P96b)

pgver=($P11b $P10b $P96b $P95b $P94b)

#pgver=($P11b)

echo "###Cleaning up Exsisting output folder###"

    rm -rf $buildPATH/pginstaller/sandboxes/win64/*
    rm -rf $buildPATH/pginstaller/sandboxes/osx64/*
    rm -rf $buildPATH/pginstaller/sandboxes/bam2/*
    
#echo "###Confirming that sandbox directories are empty###"
#    echo "##Checking sandboxes/bam...##"
#    find $buildPATH/pginstaller/sandboxes/bam2/ -type f
#        if [[ $? -ne 0 ]]; then
#            echo "***sandboxes/bam2 ISN'T EMPTY! SCRIPT HALTED***"
#            return 1
#        else
#            echo "***sandboxes/bam2 is empty, script continuing***"
#        fi
#   
#    echo "##Checking sandboxes/win64...##"
#    find $buildPATH/pginstaller/sandboxes/win64/ -type f
#        if [[ $? -ne 0 ]]; then
#            echo "***sandboxes/win64 ISN'T EMPTY! SCRIPT HALTED***"
#            return 1
#        else
#            echo "***sandboxes/win64 is empty, script continuing***"
#        fi
#        
#    echo "##Checking sandboxes/osx64...##"
#    find $buildPATH/pginstaller/sandboxes/win64/ -type f
#        if [[ $? -ne 0 ]]; then
#            echo "***sandboxes/osx64 ISN'T EMPTY! SCRIPT HALTED***"
#            return 1
#        else
#            echo "***sandboxes/osx64 is empty, script continuing***"
#        fi

#echo "###Pulling down latest BAM2 - Version $bam2b###"
#
#    scp -p $mirror:/data/pgc/out/bam2-$bam2b.tar.bz2 $buildPATH/pginstaller/sandboxes/bam2/
#    scp -p $mirror:/data/pgc/out/bam2-$bam2b.tar.bz2.sha512 $buildPATH/pginstaller/sandboxes/bam2/
#
#echo "###Verifying BAM2 VERSION $bam2b Tarball###"
#
#    diff <(sha512sum $buildPATH/pginstaller/sandboxes/bam2/bam2-$bam2b.tar.bz2 | awk -F'/' '{print $1}') <(ssh $mirror "sha512sum /data/pgc/out/bam2-$bam2b.tar.bz2" | awk -F'/' '{print $1}')
#    
#    if [[ $? -ne 0 ]]; then
#        echo "***BAM VERSION $bam2b TARBALL VERIFICATION FAILED***"
#        break
#    else
#        echo "***BAM2 VERSION $bam2b TARBALL VERIFICATION SUCEEDED***"
#    fi
#    
#echo "###Comparing SHA512 files to ensure the SHA512 files match###"
#
#    diff $buildPATH/pginstaller/sandboxes/bam2/bam2-$bam2b.tar.bz2.sha512 <(ssh $mirror "cat /data/pgc/out/bam2-$bam2b.tar.bz2.sha512")
#    
#    if [[ $? -ne 0 ]]; then
#        echo "***BAM SHA512 VERIFICATION FAILED***"
#        break
#    else
#        echo "***BAM SHA512 VERIFICATION SUCEEDED***"
#    fi

#echo "###Pulling down latest BAM4 - Version $bam4b###"
#
#    scp -p $mirror:/data/pgc/out/pgdevops-$bam4b.tar.bz2 $buildPATH/pginstaller/sandboxes/pgdevops/
#    scp -p $mirror:/data/pgc/out/pgdevops-$bam4b.tar.bz2.sha512 $buildPATH/pginstaller/sandboxes/pgdevops/
#
#echo "###Verifying BAM4 VERSION $bam4b Tarball###"
#
#    diff <(sha512sum $buildPATH/pginstaller/sandboxes/pgdevops/pgdevops-$bam4b.tar.bz2 | awk -F'/' '{print $1}') <(ssh $mirror "sha512sum /data/pgc/out/pgdevops-$bam4b.tar.bz2" | awk -F'/' '{print $1}')
#
#    if [[ $? -ne 0 ]]; then
#        echo "***BAM4 VERSION $bam4b TARBALL VERIFICATION FAILED***"
#        break
#    else
#        echo "***BAM4 VERSION $bam4b TARBALL VERIFICATION SUCEEDED***"
#    fi
#
#echo "###Comparing SHA512 files to ensure the SHA512 files match###"
#
#    diff $buildPATH/pginstaller/sandboxes/pgdevops/pgdevops-$bam4b.tar.bz2.sha512 <(ssh $mirror "cat /data/pgc/out/pgdevops-$bam4b.tar.bz2.sha512")
#
#    if [[ $? -ne 0 ]]; then
#        echo "***BAM4 SHA512 VERIFICATION FAILED***"
#        break
#    else
#        echo "***BAM4 SHA512 VERIFICATION SUCEEDED***"
#    fi

for i in "${pgver[@]}"

do

    echo "###Pulling down WIN64 Version $i sandbox and Sha512 files###"

        scp -p $mirror:/data/pgc/out/bigsql-$i-win64.zip $buildPATH/pginstaller/sandboxes/win64/
        scp -p $mirror:/data/pgc/out/bigsql-$i-win64.zip.sha512 $buildPATH/pginstaller/sandboxes/win64/

    echo "###Verifying WIN64 sandbox###"

        diff <(sha512sum $buildPATH/pginstaller/sandboxes/win64/bigsql-$i-win64.zip | awk -F'/' '{print $1}') <(ssh $mirror "sha512sum /data/pgc/out/bigsql-$i-win64.zip" | awk -F'/' '{print $1}')
        
        if [[ $? -ne 0 ]]; then
            echo "***WIN64 Version $i SANDBOX VERIFICATION FAILED***"
            break
        else
            echo "***WIN64 Version $i SANDBOX VERIFICATION SUCEEDED***"
        fi
        
    echo "###Verifying WIN64-$i.zip.sha512###"

        diff $buildPATH/pginstaller/sandboxes/win64/bigsql-$i-win64.zip.sha512 <(ssh $mirror "cat /data/pgc/out/bigsql-$i-win64.zip.sha512")
        
            if [[ $? -ne 0 ]]; then
                echo "***WIN64 - VERSION $i SHA512 VERIFICATION FAILED***"
                break
            else
                echo "***WIN64 - VERSION $i SHA512 VERIFICATION SUCEEDED***"
            fi

    echo "###Pulling down OSX64 Version $i sandbox and Sha512 files###"
            
        scp -p $mirror:/data/pgc/out/bigsql-$i-osx64.tar.bz2 $buildPATH/pginstaller/sandboxes/osx64/
        scp -p $mirror:/data/pgc/out/bigsql-$i-osx64.tar.bz2.sha512 $buildPATH/pginstaller/sandboxes/osx64/

    echo "###Verifying OSX64 sandbox###"

        diff <(sha512sum $buildPATH/pginstaller/sandboxes/osx64/bigsql-$i-osx64.tar.bz2 | awk -F'/' '{print $1}') <(ssh $mirror "sha512sum /data/pgc/out/bigsql-$i-osx64.tar.bz2" | awk -F'/' '{print $1}')
        
        if [[ $? -ne 0 ]]; then
            echo "***OSX64 Version $i SANDBOX VERIFICATION FAILED***"
            break
        else
            echo "***OSX64 Version $i SANDBOX VERIFICATION SUCEEDED***"
        fi
        
    echo "###Verifying OSX64-$i.zip.sha512###"

        diff $buildPATH/pginstaller/sandboxes/osx64/bigsql-$i-osx64.tar.bz2.sha512 <(ssh $mirror "cat /data/pgc/out/bigsql-$i-osx64.tar.bz2.sha512")
        
            if [[ $? -ne 0 ]]; then
                echo "***OSX64 - VERSION $i SHA512 VERIFICATION FAILED***"
                break
            else
                echo "***OSX64 - VERSION $i SHA512 VERIFICATION SUCEEDED***"
            fi
done
