#!/bin/bash -e
set -x
OSSFS=../src/ossfs

: ${OSSFS_CREDENTIALS_FILE:=$(eval echo ~${SUDO_USER}/.passwd-ossfs)}

: ${TEST_BUCKET_1:="ossfs-fuse-bucket"}
TEST_BUCKET_MOUNT_POINT_1=/mnt/${TEST_BUCKET_1}

if [ ! -f "$OSSFS_CREDENTIALS_FILE" ]
then
	echo "Missing credentials file: $OSSFS_CREDENTIALS_FILE"
	exit 1
fi
chmod 600 "$OSSFS_CREDENTIALS_FILE"
