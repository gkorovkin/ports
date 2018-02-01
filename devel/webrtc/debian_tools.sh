#!/bin/bash

WEBRTC_BRANCH=56
WEBRTC_COMMIT=f4f8de6631c1b05be8bb57e622535e2ec73d89fb

DEPOT_TOOLS_COMMIT=7da798be1060e555f973905519d526dcbd6f7f88

[ -r ./version ] && . ./version

if [ ! -n "$BUILDTYPE" ]
then
	export BUILDTYPE=Release
fi

# Do not package tests and examples
OMIT_TESTS=yes

# Exit on errors
set -e

download_pristine()
{
	mkdir webrtc
	pushd webrtc >/dev/null

	if [ ! -d depot_tools ]
	then
		echo "Checking out depot_tools source..."
		git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git depot_tools
		pushd depot_tools
		git checkout $DEPOT_TOOLS_COMMIT
		git reset --hard
		popd >/dev/null
	fi
	export PATH="$PWD/depot_tools:$PATH"

	echo "Checking out webrtc source..."
	fetch --nohooks webrtc

	pushd src
	git checkout -b $WEBRTC_BRANCH branch-heads/$WEBRTC_BRANCH
	git checkout $WEBRTC_COMMIT
	git reset --hard

	GIT_COMMIT=`git log --no-color -1 --oneline | cut -d" " -f1`
	GIT_DATE=`git log --no-color -1 --date=iso | sed -ne "s/Date:\s\+\(.*\).*/\1/p" | cut -d" " -f1 | tr -d "-"`

	export WEBRTC_VERSION="$WEBRTC_BRANCH+$GIT_DATE.git$GIT_COMMIT"

	popd >/dev/null

	echo "Running hooks..."
	gclient sync

	src/setup_links.py --force --no-prompt
	gclient sync

	mkdir -p src/chromium/src/third_party/openssl
	(cd src/third_party && ln -s ../chromium/src/third_party/openssl openssl)

	popd >/dev/null

	echo "Creating webrtc_$WEBRTC_VERSION.orig.tar.xz..."
	tar --exclude-vcs -c webrtc | xz -ze9 > "./webrtc_$WEBRTC_VERSION.orig.tar.xz"
	echo "WEBRTC_VERSION=$WEBRTC_VERSION" > ./version
	echo "Done."

	rm -Rf webrtc
}

download()
{
	if [ -z "$WEBRTC_VERSION" -o ! -f "webrtc_$WEBRTC_VERSION.orig.tar.xz" ]
	then
		if [ -d webrtc ]
		then
			rm -Rf webrtc
		fi

		download_pristine
	fi

	if [ ! -d webrtc ]
	then
		tar -xJf webrtc_$WEBRTC_VERSION.orig.tar.xz

		if [ ! -d webrtc ]
		then
			echo "The source archive is invalid"
			exit 1
		fi

		cp -R debian webrtc/

		WEBRTC_PREV_VERSION=`cat webrtc/debian/changelog | sed '/webrtc/!d' | sed 'q1' | sed 's/webrtc\ (//' | sed 's/-.*).*//'`

		if test "$WEBRTC_PREV_VERSION" != "$WEBRTC_VERSION"
		then
			dch -v "$WEBRTC_VERSION-1mind1" -c webrtc/debian/changelog "Updated to a new upstream version"
		fi
	fi
}

configure()
{
	export PATH=$PATH:$PWD/depot_tools

	# See if gold linker is available
	if [ -z "$HAS_GOLD" ]
	then
		local BINUTILS_VERSION=`dpkg-query -W -f \\\${Version} binutils`
		if dpkg --compare-versions "$BINUTILS_VERSION" ge "2.23.1-1~exp3"
		then
			local HAS_GOLD=true
		else
			local HAS_GOLD=false
		fi
	fi

	local OPENSSL_INCLUDE_DIR=`pkg-config --variable=includedir openssl`
	if [ -z "$OPENSSL_INCLUDE_FLAG" ]
	then
		OPENSSL_INCLUDE_DIR="/usr/include"
	fi

	local GN_ARGS="is_debug=false symbol_level=2 is_component_build=false is_clang=false linux_use_bundled_binutils=false treat_warnings_as_errors=false use_debug_fission=false use_gold=${HAS_GOLD} use_sysroot=false proprietary_codecs=true rtc_build_expat=true rtc_build_json=true rtc_build_libevent=true rtc_build_libjpeg=false rtc_build_libsrtp=true rtc_build_libvpx=true rtc_build_opus=true rtc_use_openmax_dl=true rtc_build_ssl=false rtc_ssl_root=\"$OPENSSL_INCLUDE_DIR\" rtc_enable_libevent=true rtc_enable_protobuf=false rtc_include_opus=true rtc_include_ilbc=true rtc_include_tests=false rtc_initialize_ffmpeg=false rtc_libvpx_build_vp9=true rtc_use_h264=true use_system_libjpeg=true"

	(cd src && gn gen "out/$BUILDTYPE" "--args=${GN_ARGS}")

	#(cd src && gclient runhooks --force)
}

build()
{
	export PATH=$PATH:$PWD/depot_tools

	(cd "src/out/$BUILDTYPE" && ninja -v $NUMJOBS)
}

libraries()
{
	pushd src >/dev/null

	if [ ! -n "$DEB_HOST_MULTIARCH" ]
	then
		set +e
		export DEB_HOST_MULTIARCH=`dpkg-architecture -qDEB_HOST_MULTIARCH`
		set -e
	fi

	local LIBS_LIST=`find ./out/$BUILDTYPE/obj -type f -a -name '*.a'`

	mkdir -p ./out/libs/$DEB_HOST_MULTIARCH/webrtc

	for LIB in $LIBS_LIST
	do
		local LIBNAME=`basename $LIB`

		# This variant is needed if gyp generates makefiles that generate thin static libs
#		echo $LIBNAME
#		ar -q ./out/libs/$LIBNAME $(ar -t $LIB)

		cp $LIB ./out/libs/$DEB_HOST_MULTIARCH/webrtc/
		ranlib -D ./out/libs/$DEB_HOST_MULTIARCH/webrtc/$LIBNAME
	done

	LIBS_LIST=`find ./out/$BUILDTYPE/obj -type f -a -name '*.so'`

	for LIB in $LIBS_LIST
	do
		cp $LIB ./out/libs/$DEB_HOST_MULTIARCH/
	done

	popd >/dev/null
}

headers()
{
	pushd src >/dev/null
	pushd webrtc >/dev/null

	if [ "$OMIT_TESTS" == "yes" ]
	then
		HDRS_LIST=`find . -type f -a -name '*.h' | grep -vF 'test/'`
	else
		HDRS_LIST=`find . -type f -a -name '*.h'`
	fi

	mkdir -p ../out/headers/webrtc

	for HDR in $HDRS_LIST
	do
		cp --parents $HDR ../out/headers/webrtc
	done

	popd >/dev/null
	popd >/dev/null
}

binaries()
{
	pushd src >/dev/null

	BIN_LIST=`find ./out/$BUILDTYPE -type f -a -executable -a ! -name '*.so'`
	mkdir -p ./out/bin
	for BIN in $BIN_LIST
	do
		cp $BIN out/bin/
	done

	popd >/dev/null
}

help()
{
	echo "Script'$0' supports commands: 'download', 'download_pristine', 'configure', 'build', 'libraries', 'headers'"
}

if [ $# == 0 ]
then
	help
else
	for ARG in $@
	do
		$(echo $ARG | sed 's/-*//') 2> /dev/null || \
			echo "Unknown for script '$0' command '$ARG', use '$0 [help]'"
	done
fi
