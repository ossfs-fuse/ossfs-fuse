#!/bin/bash

#
# By default tests run against a local s3proxy instance.  To run against 
# Aliyun OSS, specify the following variables:
#
# OSSFS_CREDENTIALS_FILE=keyfile      s3fs format key file
# TEST_BUCKET_1=bucket               Name of bucket to use 
#
# Example: 
#
# OSSFS_CREDENTIALS_FILE=keyfile TEST_BUCKET_1=bucket ./small-integration-test.sh
#

set -o xtrace
set -o errexit

# Require root
REQUIRE_ROOT=require-root.sh
source $REQUIRE_ROOT
source integration-test-common.sh

function retry {
    set +o errexit
    N=$1; shift;
    status=0
    for i in $(seq $N); do
        $@
        status=$?
        if [ $status == 0 ]; then
            break
        fi
        sleep 1
    done

    if [ $status != 0 ]; then
        echo "timeout waiting for $@"
    fi
    set -o errexit
    return $status
}

# Mount the bucket
if [ ! -d $TEST_BUCKET_MOUNT_POINT_1 ]
then
	mkdir -p $TEST_BUCKET_MOUNT_POINT_1
fi

stdbuf -oL -eL $OSSFS $TEST_BUCKET_1 $TEST_BUCKET_MOUNT_POINT_1 \
    -o passwd_file=$OSSFS_CREDENTIALS_FILE

retry 30 grep $TEST_BUCKET_MOUNT_POINT_1 /proc/mounts || exit 1

./integration-test-main.sh $TEST_BUCKET_MOUNT_POINT_1

echo "All tests complete."
