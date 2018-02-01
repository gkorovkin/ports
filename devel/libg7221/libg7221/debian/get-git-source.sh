#!/bin/bash

BUILD_COMMIT='dbfc29d4806ecdace50379a2f4d68a992a6fec34'
#BUILD_COMMIT='v0.2.0'
# Explicitly set package version to exclude git commit and date from the release version
#LIBG7221_VERSION='0.2.0'

OLDDIR=${PWD}

set -e

rm -rf libg7221


git clone https://freeswitch.org/stash/scm/sd/libg7221.git libg7221
cd libg7221
git checkout $BUILD_COMMIT
git reset --hard

if [ ! -n "$BASE_REL" ]
then
	MAJOR_VERSION=`grep -m 1 -P 'G722_1_MAJOR_VERSION=\d+' configure.ac | sed 's/G722_1_MAJOR_VERSION=//'`
	MINOR_VERSION=`grep -m 1 -P 'G722_1_MINOR_VERSION=\d+' configure.ac | sed 's/G722_1_MINOR_VERSION=//'`
	MICRO_VERSION=`grep -m 1 -P 'G722_1_MICRO_VERSION=\d+' configure.ac | sed 's/G722_1_MICRO_VERSION=//'`

	BASE_REL="${MAJOR_VERSION}.${MINOR_VERSION}.${MICRO_VERSION}"
fi

if [ ! -n "$LIBG7221_VERSION" ]
then
	LIBG7221_GIT_COMMIT_FULL=`git log --no-color -1 --oneline --pretty=format:"%H"`
	LIBG7221_GIT_COMMIT=${LIBG7221_GIT_COMMIT_FULL:0:7}
	LIBG7221_GIT_DATE=`git log --no-color -1 --date=iso | sed -ne "s/Date:\s\+\(.*\).*/\1/p" | cut -d" " -f1 | tr -d "-"`
	LIBG7221_VERSION="${BASE_REL}+${LIBG7221_GIT_DATE}.git${LIBG7221_GIT_COMMIT}"
fi

# Remove files we dont need
rm -rf debian
rm -f build_rpm.sh src_tarball.sh unpack_g722_1_data.sh .gitattributes

cd ..

tar --exclude-vcs -cJf ${OLDDIR}/../libg7221_${LIBG7221_VERSION}.orig.tar.xz libg7221

LIBG7221_PREV_VERSION=`cat debian/changelog | sed '/libg7221/!d' | sed 'q1' | sed 's/libg7221\ (//' | sed 's/-.*).*//'`

if [ "$LIBG7221_PREV_VERSION" != "${LIBG7221_VERSION}" ]
then
	dch -v "${LIBG7221_VERSION}-1imp1" -c debian/changelog "Updated from upstream"
fi

echo LIBG7221_VERSION=$LIBG7221_VERSION >../version

rm -rf libg7221
cd ..
tar -xJf libg7221_${LIBG7221_VERSION}.orig.tar.xz

echo "LIBG7221_VERSION=${LIBG7221_VERSION}" >version
