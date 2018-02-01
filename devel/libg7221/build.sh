#!/bin/sh

BUILD_JOBS=`getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1`

cd libg7221 > /dev/null

if [ ! -r ../version ]
then
	./debian/get-git-sources.sh
fi

dpkg-buildpackage -us -uc -j$BUILD_JOBS

cd - > /dev/null
