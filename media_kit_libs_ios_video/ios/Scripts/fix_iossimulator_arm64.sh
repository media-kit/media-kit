#!/bin/sh

# https://bogo.wtf/arm64-to-sim-dylibs.html

IOSSIMULATOR=7

PLATFORM=$IOSSIMULATOR
MINOS=13.0
SDK=16.2

find ".tmp/libs/libmpv-iossimulator-arm64" -type f | while read DYLIB; do
    echo "${DYLIB}"
    xcrun vtool \
        -arch arm64 \
        -set-build-version $IOSSIMULATOR $MINOS $SDK \
        -replace \
        -output "${DYLIB}" \
        "${DYLIB}"
done

