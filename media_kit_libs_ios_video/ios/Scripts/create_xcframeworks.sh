#!/bin/sh

find ".tmp/Frameworks/ios" -name "*.framework" -type d | while read FRAMEWORK_IOS; do
    FRAMEWORK_IOSSIMULATOR=$(echo ${FRAMEWORK_IOS} | sed 's/ios/iossimulator'/g)
    FRAMEWORK_NAME=$(basename $FRAMEWORK_IOS .framework)

    echo ${FRAMEWORK_NAME}

    xcodebuild -create-xcframework \
        -framework ${FRAMEWORK_IOS} \
        -framework ${FRAMEWORK_IOSSIMULATOR} \
        -output Frameworks/${FRAMEWORK_NAME}.xcframework
done
