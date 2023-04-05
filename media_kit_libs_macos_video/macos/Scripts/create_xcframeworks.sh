#!/bin/sh

FRAMEWORKS_MACOS_DIR="$1"
XCFRAMEWORKS_DIR="$2"

find "${FRAMEWORKS_MACOS_DIR}" -name "*.framework" -type d | while read FRAMEWORK_MACOS; do
    FRAMEWORK_NAME=$(basename "$FRAMEWORK_MACOS" .framework)

    echo "${FRAMEWORK_NAME}"

    xcodebuild -create-xcframework \
        -framework "${FRAMEWORK_MACOS}" \
        -output "${XCFRAMEWORKS_DIR}/${FRAMEWORK_NAME}.xcframework"
done
