#!/bin/bash

# Copyright (C) 2013 Red Hat Inc.
# SPDX-License-Identifier:  GPL-2.0+

# This script will download and install uboot

# usage message
usage() {
    echo "
Usage: $(basename ${0}) <options>

   --target=TARGET  - target board
                      [${TARGETS}]
   --media=DEVICE   - media device file (/dev/[sdX|mmcblkX])
   --tag=KOJI TAG   - koji tag (Default is 'f22'. 'f21', 'f21-updates' etc..)

Example: $(basename ${0}) --target=panda --media=/dev/mmcblk0"
}

# check the args
while [ $# -gt 0 ]; do
    case $1 in
        --debug)
            set -x
            ;;
        -h|--help)
            usage
            ;;
        --target*)
            if echo $1 | grep '=' >/dev/null ; then
                TARGET=$(echo $1 | sed 's/^--target=//')
            else
                TARGET=$2
                shift
            fi
            ;;
        --media*)
            if echo $1 | grep '=' >/dev/null ; then
                MEDIA=$(echo $1 | sed 's/^--media=//')
            else
                MEDIA=$2
                shift
            fi
            ;;
	--tag*)
            if echo $1 | grep '=' >/dev/null ; then
                KOJI_TAG=$(echo $1 | sed 's/^--tag=//')
            else
                KOJI_TAG=$2
                shift
            fi
            ;;
        *)
            echo "$(basename ${0}): Error - ${1}"
            usage
            exit 1
            ;;
        esac
    shift
done

DIR=$(dirname $0)
BOARDDIR=boards.d
TARGETS=$(ls -1 ${DIR}/${BOARDDIR})
TARGETS=$(echo ${TARGETS} | sed -e 's/[[:space:]]/|/g')

# check if media exists
if [[ ! -e $MEDIA ]] ; then
        echo "Missing media"
        usage
        exit 1
fi

if [[ $TARGET = '' ]] ; then
        echo "Missing target"
        usage
        exit 1
fi
if [[ $KOJI_TAG = '' ]] ; then 
	KOJI_TAG=f22
fi

sudo rm -rf /tmp/root &> /dev/null
mkdir /tmp/root

# get the latest uboot
pushd /tmp/root &> /dev/null
koji download-build --arch=armv7hl --latestfrom=$KOJI_TAG uboot-tools
# unpack uboot
rpm2cpio uboot-images*.rpm | cpio -idv &> /dev/null
popd &> /dev/null

# determine uboot and write to disk 
if [ "$TARGET" = "" ]; then
        echo "= No U-boot will be written."
        TARGET="Mystery Board"
else
        . "${DIR}/${BOARDDIR}/${TARGET}"
fi

echo "= Complete!"
