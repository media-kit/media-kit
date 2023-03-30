#!/bin/sh

xcodebuild -create-xcframework \
    -framework .tmp/Frameworks/ios/MPV.framework \
    -framework .tmp/Frameworks/iossimulator/MPV.framework \
    -output Frameworks/MPV.xcframework
