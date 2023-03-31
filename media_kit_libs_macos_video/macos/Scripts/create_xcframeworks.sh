#!/bin/sh

find ".tmp/Frameworks/macos" -name "*.framework" -type d | while read FRAMEWORK_MACOS; do
    FRAMEWORK_NAME=$(basename $FRAMEWORK_MACOS .framework)

    echo ${FRAMEWORK_NAME}

    xcodebuild -create-xcframework \
        -framework ${FRAMEWORK_MACOS} \
        -output Frameworks/${FRAMEWORK_NAME}.xcframework
done
