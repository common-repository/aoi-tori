#!/usr/bin/env bash

# args
MSG=${1-'deploy from git'}
BRANCH=${2-'trunk'}

# paths
SRC_DIR=$(git rev-parse --show-toplevel)
DIR_NAME=$(basename $SRC_DIR)
DEST_DIR=../../svn/$DIR_NAME/$BRANCH

# build first
if [ -f "$SRC_DIR/bin/build" ]; then
	$SRC_DIR/bin/build
fi

# make sure we're deploying from the right dir
if [ ! -d "$SRC_DIR/.git" ]; then
	echo "$SRC_DIR doesn't seem to be a git repository"
	exit
fi

# make sure the destination dir exists
mkdir -p $DEST_DIR
svn add $DEST_DIR 2> /dev/null

# delete everything except .svn dirs
for file in $(find $DEST_DIR/* -type f -and -not -path "*.svn*")
do
	rm $file
	echo "$file deleted"
done

# copy everything over from git
rsync --recursive --exclude='*.git*' $SRC_DIR/* $DEST_DIR

cd $DEST_DIR

# check .svnignore
for file in $(cat "$SRC_DIR/.svnignore" 2> /dev/null)
do
	rm -rf $file
	echo "$file deleted"
done

# svn addremove
svn stat | awk '/^\?/ {print $2}' | xargs svn add > /dev/null 2>&1
svn stat | awk '/^\!/ {print $2}' | xargs svn rm --force

svn stat

svn ci -m "$MSG"
