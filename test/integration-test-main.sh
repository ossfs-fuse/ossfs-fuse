#!/bin/bash
# -*- coding: utf-8 -*-

set -o xtrace
set -o errexit

COMMON=integration-test-common.sh
source $COMMON

# Configuration
TEST_TEXT="HELLO WORLD"
TEST_TEXT_FILE=test-ossfs.txt
TEST_DIR=testdir
ALT_TEST_TEXT_FILE=test-ossfs-ALT.txt
TEST_TEXT_FILE_LENGTH=15
BIG_FILE=big-file-ossfs.txt
BIG_FILE_LENGTH=$((25 * 1024 * 1024))

########################
# OSSFS-Fuse Test Cases #
########################

function mk_test_file {
    if [ $# == 0 ]; then
        TEXT=$TEST_TEXT
    else
        TEXT=$1
    fi
    echo $TEXT > $TEST_TEXT_FILE
    if [ ! -e $TEST_TEXT_FILE ]
    then
        echo "Could not create file ${TEST_TEXT_FILE}, it does not exist"
        exit 1
    fi
}

function rm_test_file {
    if [ $# == 0 ]; then
        FILE=$TEST_TEXT_FILE
    else
        FILE=$1
    fi
    rm -f $FILE

    if [ -e $FILE ]
    then
        echo "Could not cleanup file ${TEST_TEXT_FILE}"
        exit 1
    fi
}

function mk_test_dir {
    mkdir ${TEST_DIR}

    if [ ! -d ${TEST_DIR} ]; then
        echo "Directory ${TEST_DIR} was not created"
        exit 1
    fi
}

function rm_test_dir {
    rmdir ${TEST_DIR}
    if [ -e $TEST_DIR ]; then
        echo "Could not remove the test directory, it still exists: ${TEST_DIR}"
        exit 1
    fi
}

function remove_dir {
    rm -rf $1
    if [ -e $1 ]; then
        echo "Could not remove the test directory, it still exists: $1"
        exit 1
    fi
}

function test_append_file {
    echo "Testing append to file ..."
    # Write a small test file
    for x in `seq 1 $TEST_TEXT_FILE_LENGTH`
    do
       echo "echo ${TEST_TEXT} to ${TEST_TEXT_FILE}"
    done > ${TEST_TEXT_FILE}

    # Verify contents of file
    echo "Verifying length of test file"
    FILE_LENGTH=`wc -l $TEST_TEXT_FILE | awk '{print $1}'`
    if [ "$FILE_LENGTH" -ne "$TEST_TEXT_FILE_LENGTH" ]
    then
       echo "error: expected $TEST_TEXT_FILE_LENGTH , got $FILE_LENGTH"
       exit 1
    fi

    rm_test_file
}

function test_mv_file {
    echo "Testing mv file function ..."

    # if the rename file exists, delete it
    if [ -e $ALT_TEST_TEXT_FILE ]
    then
       rm $ALT_TEST_TEXT_FILE
    fi

    if [ -e $ALT_TEST_TEXT_FILE ]
    then
       echo "Could not delete file ${ALT_TEST_TEXT_FILE}, it still exists"
       exit 1
    fi

    # create the test file again
    mk_test_file

    #rename the test file
    mv $TEST_TEXT_FILE $ALT_TEST_TEXT_FILE
    if [ ! -e $ALT_TEST_TEXT_FILE ]
    then
       echo "Could not move file"
       exit 1
    fi

    # Check the contents of the alt file
    ALT_TEXT_LENGTH=`echo $TEST_TEXT | wc -c | awk '{print $1}'`
    ALT_FILE_LENGTH=`wc -c $ALT_TEST_TEXT_FILE | awk '{print $1}'`
    if [ "$ALT_FILE_LENGTH" -ne "$ALT_TEXT_LENGTH" ]
    then
       echo "moved file length is not as expected expected: $ALT_TEXT_LENGTH  got: $ALT_FILE_LENGTH"
       exit 1
    fi

    # clean up
    rm_test_file $ALT_TEST_TEXT_FILE
}

function test_mv_directory {
    echo "Testing mv directory function ..."
    if [ -e $TEST_DIR ]; then
       echo "Unexpected, this file/directory exists: ${TEST_DIR}"
       exit 1
    fi

    mk_test_dir

    mv ${TEST_DIR} ${TEST_DIR}_rename

    if [ ! -d "${TEST_DIR}_rename" ]; then
       echo "Directory ${TEST_DIR} was not renamed"
       exit 1
    fi

    rmdir ${TEST_DIR}_rename
    if [ -e "${TEST_DIR}_rename" ]; then
       echo "Could not remove the test directory, it still exists: ${TEST_DIR}_rename"
       exit 1
    fi
}

function test_redirects {
    echo "Testing redirects ..."

    mk_test_file ABCDEF

    CONTENT=`cat $TEST_TEXT_FILE`

    if [ ${CONTENT} != "ABCDEF" ]; then
       echo "CONTENT read is unexpected, got ${CONTENT}, expected ABCDEF"
       exit 1
    fi

    echo XYZ > $TEST_TEXT_FILE

    CONTENT=`cat $TEST_TEXT_FILE`

    if [ ${CONTENT} != "XYZ" ]; then
       echo "CONTENT read is unexpected, got ${CONTENT}, expected XYZ"
       exit 1
    fi

    echo 123456 >> $TEST_TEXT_FILE

    LINE1=`sed -n '1,1p' $TEST_TEXT_FILE`
    LINE2=`sed -n '2,2p' $TEST_TEXT_FILE`

    if [ ${LINE1} != "XYZ" ]; then
       echo "LINE1 was not as expected, got ${LINE1}, expected XYZ"
       exit 1
    fi

    if [ ${LINE2} != "123456" ]; then
       echo "LINE2 was not as expected, got ${LINE2}, expected 123456"
       exit 1
    fi

    # clean up
    rm_test_file
}

function test_mkdir_rmdir {
    echo "Testing creation/removal of a directory"

    if [ -e $TEST_DIR ]; then
       echo "Unexpected, this file/directory exists: ${TEST_DIR}"
       exit 1
    fi

    mk_test_dir
    rm_test_dir
}

function test_chmod {
    echo "Testing chmod file function ..."

    # create the test file again
    mk_test_file

    ORIGINAL_PERMISSIONS=$(stat --format=%a $TEST_TEXT_FILE)

    chmod 777 $TEST_TEXT_FILE;

    # if they're the same, we have a problem.
    if [ $(stat --format=%a $TEST_TEXT_FILE) == $ORIGINAL_PERMISSIONS ]
    then
      echo "Could not modify $TEST_TEXT_FILE permissions"
      exit 1
    fi

    # clean up
    rm_test_file
}

function test_chown {
    echo "Testing chown file function ..."

    # create the test file again
    mk_test_file

    ORIGINAL_PERMISSIONS=$(stat --format=%u:%g $TEST_TEXT_FILE)

    chown 1000:1000 $TEST_TEXT_FILE;

    # if they're the same, we have a problem.
    if [ $(stat --format=%a $TEST_TEXT_FILE) == $ORIGINAL_PERMISSIONS ]
    then
      echo "Could not modify $TEST_TEXT_FILE ownership"
      exit 1
    fi

    # clean up
    rm_test_file
}

function test_list {
    echo "Testing list"
    mk_test_file
    mk_test_dir

    file_cnt=$(ls -1 | wc -l)
    if [ $file_cnt != 2 ]; then
        echo "Expected 2 file but got $file_cnt"
        exit 1
    fi

    rm_test_file
    rm_test_dir
}

function test_remove_nonempty_directory {
    echo "Testing removing a non-empty directory"
    mk_test_dir
    touch "${TEST_DIR}/file"
    rmdir "${TEST_DIR}" 2>&1 | grep -q "Directory not empty"
    rm "${TEST_DIR}/file"
    rm_test_dir
}

function test_rename_before_close {
    echo "Testing rename before close ..."
    (
        echo foo
        mv $TEST_TEXT_FILE ${TEST_TEXT_FILE}.new
    ) > $TEST_TEXT_FILE

    if ! cmp <(echo foo) ${TEST_TEXT_FILE}.new; then
        echo "rename before close failed"
        exit 1
    fi

    rm_test_file ${TEST_TEXT_FILE}.new
    rm -f ${TEST_TEXT_FILE}
}

function test_multipart_upload {
    echo "Testing multi-part upload ..."
    dd if=/dev/urandom of="/tmp/${BIG_FILE}" bs=$BIG_FILE_LENGTH count=1
    dd if="/tmp/${BIG_FILE}" of="${BIG_FILE}" bs=$BIG_FILE_LENGTH count=1

    # Verify contents of file
    echo "Comparing test file"
    if ! cmp "/tmp/${BIG_FILE}" "${BIG_FILE}"
    then
       exit 1
    fi

    rm -f "/tmp/${BIG_FILE}"
    rm_test_file "${BIG_FILE}"
}

function test_multipart_copy {
    echo "Testing multi-part copy ..."
    dd if=/dev/urandom of="/tmp/${BIG_FILE}" bs=$BIG_FILE_LENGTH count=1
    dd if="/tmp/${BIG_FILE}" of="${BIG_FILE}" bs=$BIG_FILE_LENGTH count=1
    mv "${BIG_FILE}" "${BIG_FILE}-copy"

    # Verify contents of file
    echo "Comparing test file"
    if ! cmp "/tmp/${BIG_FILE}" "${BIG_FILE}-copy"
    then
       exit 1
    fi

    rm -f "/tmp/${BIG_FILE}"
    rm_test_file "${BIG_FILE}-copy"
}

function test_dir_with_special_characters {
    echo "Testing special characters ..."

    ls 'special' 2>&1 | grep -q 'No such file or directory'
    ls 'special?' 2>&1 | grep -q 'No such file or directory'
    ls 'special*' 2>&1 | grep -q 'No such file or directory'
    ls 'special~' 2>&1 | grep -q 'No such file or directory'
    ls 'specialµ' 2>&1 | grep -q 'No such file or directory'
}

function test_symlink {
    echo "Testing symlinks ..."

    rm -f $TEST_TEXT_FILE
    rm -f $ALT_TEST_TEXT_FILE
    echo foo > $TEST_TEXT_FILE

    ln -s $TEST_TEXT_FILE $ALT_TEST_TEXT_FILE
    cmp $TEST_TEXT_FILE $ALT_TEST_TEXT_FILE

    rm -f $TEST_TEXT_FILE

    [ -L $ALT_TEST_TEXT_FILE ]
    [ ! -f $ALT_TEST_TEXT_FILE ]
}

#########################
# OSSFS-Fuse Test Cases #
#########################

function test_file_with_special_characters {
    echo "Testing special characters ..."

    echo "content-special" > "file-special"
    #echo "content-special?" > "file-special?"
    echo "content-special*" > "file-special*"
    echo "content-special~" > "file-special~"
    echo "content-specialµ" > "file-specialµ"
    
    if [ "content-special" != $(cat "file-special") ]
    then
        exit 1
    fi
    
    #if [ "content-special?" -ne $(cat "file-special?") ]
    #then
    #    exit 1
    #fi
    
    if [ "content-special*" != $(cat "file-special*") ]
    then
        exit 1
    fi
    
    if [ "content-special~" != $(cat "file-special~") ]
    then
        exit 1
    fi
    
    if [ "content-specialµ" != $(cat "file-specialµ") ]
    then
        exit 1
    fi

    rm_test_file "file-special"
    #rm_test_file "file-special?"
    rm_test_file "file-special*"
    rm_test_file "file-special~"
    rm_test_file "file-specialµ"
}

function test_dd_create_big_file {
    echo "Testing ${FUNCNAME[0]} ..."
    
    file_of_6G="file_of_6G"
    length_of_6G=$((1024 * 1024 * 1024 * 6))
    
    dd if=/dev/urandom of=${file_of_6G} bs=1M count=$((1024 * 6))
    
    if [ $(ls -l "${file_of_6G}"  | awk '{print $5}') -ne "${length_of_6G}" ]
    then
        echo "File length $(ls -l ${file_of_6G}  | awk '{print $5}') dosen't match exception ${length_of_6G}."
        exit 1
    fi
    rm_test_file "${file_of_6G}"
}

function test_dd_copy_big_file_in {
    echo "Testing ${FUNCNAME[0]} ..."
    
    file_of_6G="file_of_6G"
    length_of_6G=$((1024 * 1024 * 1024 * 6))

    dd if=/dev/urandom of="/tmp/${file_of_6G}" bs=1M count=$((1024 * 6))
    dd if="/tmp/${file_of_6G}" of="${file_of_6G}" bs=1M count=$((1024 * 6))

    # Verify contents of file
    echo "Comparing test file"
    if ! cmp "/tmp/${file_of_6G}" "${file_of_6G}"
    then
       exit 1
    fi

    rm -f "/tmp/${file_of_6G}"
    rm_test_file "${file_of_6G}"
}

function test_dd_copy_big_file_out {
    echo "Testing ${FUNCNAME[0]} ..."
    
    file_of_6G="file_of_6G"
    length_of_6G=$((1024 * 1024 * 1024 * 6))

    dd if=/dev/urandom of="${file_of_6G}" bs=1M count=$((1024 * 6))
    dd if="${file_of_6G}" of="/tmp/${file_of_6G}" bs=1M count=$((1024 * 6))

    # Verify contents of file
    echo "Comparing test file"
    if ! cmp "/tmp/${file_of_6G}" "${file_of_6G}"
    then
       exit 1
    fi

    rm -f "/tmp/${file_of_6G}"
    rm_test_file "${file_of_6G}"
}

function test_move_big_file_inner {
    echo "Testing ${FUNCNAME[0]} ..."
    
    file_of_6G="file_of_6G"
    length_of_6G=$((1024 * 1024 * 1024 * 6))

    dd if=/dev/urandom of="/tmp/${file_of_6G}" bs=1M count=$((1024 * 6))
    dd if="/tmp/${file_of_6G}" of="${file_of_6G}" bs=1M count=$((1024 * 6))
    mv "${file_of_6G}" "${file_of_6G}-copy"

    # Verify contents of file
    echo "Comparing test file"
    if ! cmp "/tmp/${file_of_6G}" "${file_of_6G}-copy"
    then
       exit 1
    fi

    rm -f "/tmp/${file_of_6G}"
    rm_test_file "${file_of_6G}-copy"
}

function test_move_big_file_in {
    echo "Testing ${FUNCNAME[0]} ..."
    
    file_of_6G="file_of_6G"
    length_of_6G=$((1024 * 1024 * 1024 * 6))

    dd if=/dev/urandom of="/tmp/${file_of_6G}" bs=1M count=$((1024 * 6))
    dd if="/tmp/${file_of_6G}" of="/tmp/${file_of_6G}-copy" bs=1M count=$((1024 * 6))
    mv "/tmp/${file_of_6G}-copy" "${file_of_6G}-copy"

    # Verify contents of file
    echo "Comparing test file"
    if ! cmp "/tmp/${file_of_6G}" "${file_of_6G}-copy"
    then
       exit 1
    fi

    rm -f "/tmp/${file_of_6G}"
    rm_test_file "${file_of_6G}-copy"
}

function test_move_big_file_out {
    echo "Testing ${FUNCNAME[0]} ..."
    
    file_of_6G="file_of_6G"
    length_of_6G=$((1024 * 1024 * 1024 * 6))

    dd if=/dev/urandom of="${file_of_6G}" bs=1M count=$((1024 * 6))
    dd if="${file_of_6G}" of="${file_of_6G}-copy" bs=1M count=$((1024 * 6))
    mv "${file_of_6G}-copy" "/tmp/${file_of_6G}-copy"

    # Verify contents of file
    echo "Comparing test file"
    if ! cmp "/tmp/${file_of_6G}-copy" "${file_of_6G}"
    then
       exit 1
    fi

    rm -f "/tmp/${file_of_6G}-copy"
    rm_test_file "${file_of_6G}"
}

function test_move_parallel_dir_with_many_file {
    mkdir origin-dir
    cd origin-dir
    for i in {1..1234}
    do
        echo Hello > "file_$i";
    done
    cd ..
    mv origin-dir renamed-dir
    if [ $(ls renamed-dir | wc -l) -ne "1234" ]
    then
        exit 1
    fi
    remove_dir origin-dir
    remove_dir renamed-dir
}

function test_move_nest_dir_with_many_file {
    mkdir child-dir parent-dir
    cd child-dir
    for i in {1..1234}
    do
        echo Hello > "file_$i";
    done
    cd ..
    mv child-dir parent-dir
    if [ $(ls parent-dir/child-dir | wc -l) -ne "1234" ]
    then
        exit 1
    fi
    remove_dir parent-dir
}

function run_all_tests {
    
     
    test_append_file
    test_mv_file
    test_mv_directory
    test_redirects
    test_mkdir_rmdir
    test_chmod
    test_chown
    test_list
    test_remove_nonempty_directory
    # TODO: broken: https://github.com/s3fs-fuse/s3fs-fuse/issues/145
    #test_rename_before_close
    test_multipart_upload
    # TODO: test disabled until OSSProxy 1.5.0 is released
    #test_multipart_copy
    test_dir_with_special_characters
    test_file_with_special_characters
    test_symlink
     
    test_dd_create_big_file
    test_dd_copy_big_file_in
    test_dd_copy_big_file_out
    test_move_big_file_inner
    test_move_big_file_in
    test_move_big_file_out
    
    test_move_parallel_dir_with_many_file
    test_move_nest_dir_with_many_file
}

# Mount the bucket
CUR_DIR=`pwd`
TEST_BUCKET_MOUNT_POINT_1=$1
if [ "$TEST_BUCKET_MOUNT_POINT_1" == "" ]; then
    echo "Mountpoint missing"
    exit 1
fi
cd $TEST_BUCKET_MOUNT_POINT_1

if [ -e $TEST_TEXT_FILE ]
then
  rm -f $TEST_TEXT_FILE
fi

run_all_tests

# Unmount the bucket
cd $CUR_DIR
echo "All tests complete."
