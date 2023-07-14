#!/bin/sh
set -e

LIBS_VERSION=v0.4.1

case $( uname -m ) in
x86_64) LIBS_ARCH=amd64;;
arm64)  LIBS_ARCH=arm64;;
*)      echo "unsupported arch $( uname -m )" && exit 1;;
esac

rm -rf ./test/ci/macos/libs
mkdir -p ./test/ci/macos/libs
curl -s -L https://github.com/media-kit/libmpv-darwin-build/releases/download/${LIBS_VERSION}/libmpv-libs-video-${LIBS_VERSION}-macos-${LIBS_ARCH}.tar.gz | tar xvz --strip-components 1 - -C ./test/ci/macos/libs

sh ./test/ci/macos/scripts/relink_dylibs.sh @rpath $PWD/test/ci/macos/libs ./test/ci/macos/libs
