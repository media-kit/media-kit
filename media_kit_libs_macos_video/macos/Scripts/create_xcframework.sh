#!/bin/sh

SOURCE_FOLDER=".tmp/Frameworks/macos"
TARGET_FOLDER="Frameworks"

xcodebuild -create-xcframework \
    -framework "${SOURCE_FOLDER}"/MPV.framework \
    -output "${TARGET_FOLDER}"/MPV.xcframework
