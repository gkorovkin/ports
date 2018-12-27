#!/bin/bash

WEBRTC_BRANCH=59
WEBRTC_COMMIT=61fe801ad874104a2d461083f53caee4c19c51b6
DEPOT_TOOLS_COMMIT=4a28cac715bb37782fca641eb8fcd8583b5f1960


WEBRTC_DIR=$PWD #TODO arg from build

#put depot tools into tmp dir
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git /tmp/depot_tools
(cd /tmp/depot_tools && git $DEPOT_TOOLS_COMMIT && git reset --hard)
export PATH="/tmp/depot_tools:$PATH"

#collect webrtc
mkdir /tmp/webrtc
cd /tmp/webrtc

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
tar -c webrtc | xz -ze9 > "/tmp/webrtc_$WEBRTC_VERSION.orig.tar.xz"
echo "Done."

# rm -Rf webrtc
