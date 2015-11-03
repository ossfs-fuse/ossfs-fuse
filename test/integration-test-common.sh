#!/bin/bash -e
set -x
S3FS=../src/ossfs

: ${S3FS_CREDENTIALS_FILE:=$(eval echo ~${SUDO_USER}/.passwd-ossfs)}

: ${TEST_BUCKET_1:="a-ftp-test"}
TEST_BUCKET_MOUNT_POINT_1=/mnt/${TEST_BUCKET_1}

if [ ! -f "$S3FS_CREDENTIALS_FILE" ]
then
	echo "Missing credentials file: $S3FS_CREDENTIALS_FILE"
	exit 1
fi
chmod 600 "$S3FS_CREDENTIALS_FILE"
