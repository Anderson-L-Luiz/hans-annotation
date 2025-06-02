#!/bin/bash

database=""
port=9000
buckets=""
showHelp=0
test=0
testFilesBucket=""
testFiles=""
recursive=0

while getopts d:p:b:t:f:h flag
do
    case "${flag}" in
        d) database=$OPTARG;;
        p) port=$OPTARG;;
        b) buckets=$OPTARG;;
        h) showHelp=1;;
        t) test=1; testFilesBucket=$OPTARG;;
        f) test=1; testFiles=$OPTARG;;
        r) recursive=1;;
    esac
done

if [[ $showHelp -eq 1 ]]
then
    echo "Initializes a minio service"
    echo "Usage:"
    echo "  init.sh -d <minio-server-name> -p <minio-server-port> -b <list-of-buckets> [ -t <bucket-name> -f <test-file> ] [ -r ]"
    echo "Parameters: "
    echo "  -d: The minio server name"
    echo "  -p: The minio server port"
    echo "  -b: A comma seperated list of buckets to be created, e.g. video,error,test"
    echo "  -t: Activate bucket initialization with test files for specified bucket, e.g. video"
    echo "  -f: A comma seperated list of test files (as single files or folder using -r) to be copied to the bucket specified with -t parameter, e.g. file1.mp4,file1.pdf,file1timings.txt"
    echo "  -r: Activate recursive copy of test files"
    echo "Example:"
    echo "  init.sh -d assetdb -p 9001 -b assets;"
else
    echo "Initializing minio $database on port $port with buckets $buckets"
    ./mc alias set minio http://$database:$port $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD

    # Check minio status
    ./mc admin --json info minio

    # Update to latest minio version
    ./mc admin update minio

    # Check minio status
    ./mc admin --json info minio

    # Create buckets
    for i in ${buckets//,/ }
    do
        echo "Creating bucket $i"
        ./mc mb minio/$i
    done

    if [[ $test -eq 1 ]]
    then
        echo "Initializing bucket $testFilesBucket with test files"
        for i in ${testFiles//,/ }
        do
            echo "Copying $i to bucket $testFilesBucket"
            # See https://docs.min.io/minio/baremetal/reference/minio-mc/mc-cp.html
            if [[ $recursive -eq 1 ]]
            then
              ./mc cp --recursive $i minio/$testFilesBucket/
            else
              ./mc cp $i minio/$testFilesBucket/
            fi
        done
        # List bucket, see https://docs.min.io/minio/baremetal/reference/minio-mc/mc-ls.html#list-bucket-contents
        ./mc ls --recursive --versions minio/$testFilesBucket
    fi
    echo "Finished"
fi
