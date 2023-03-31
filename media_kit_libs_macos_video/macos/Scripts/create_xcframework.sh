#!/bin/sh

xcodebuild -create-xcframework \
    -framework .tmp/Frameworks/macos/MPV.framework \
    -output Frameworks/MPV.xcframework
