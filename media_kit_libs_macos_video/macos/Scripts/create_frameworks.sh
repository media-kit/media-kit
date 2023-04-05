#!/bin/sh

OS="$1"
LIBS_DIR="$2"
FRAMEWORKS_DIR="$3"

if [ "$OS" == "iossimulator" ]; then
    OS=ios
fi

find "${LIBS_DIR}" -name "*.dylib" -type f | while read DYLIB; do
    echo "${DYLIB}"

    # create framework dylib name: libavcodec.59.dylib -> Avcodec
    DYLIB_NAME=$(basename $DYLIB .dylib | sed 's/\.[0-9]*$//' | sed 's/^lib//')
    DYLIB_NAME="$(tr '[:lower:]' '[:upper:]' <<< ${DYLIB_NAME:0:1})${DYLIB_NAME:1}"

    # we get the min supported version from the arm64 version, because it is the
    # highest
    MIN_OS_VERSION=$(xcrun vtool -arch arm64 -show "${DYLIB}" | grep minos | cut -d ' ' -f6)

    # copy dylib
    mkdir -p "${FRAMEWORKS_DIR}/${DYLIB_NAME}.framework"
    cp "${DYLIB}" "${FRAMEWORKS_DIR}/${DYLIB_NAME}.framework/${DYLIB_NAME}"

    # replace DYLIB var
    DYLIB="${FRAMEWORKS_DIR}/${DYLIB_NAME}.framework/${DYLIB_NAME}"

    codesign --force -s - "${DYLIB}"

    # update dylib id
    NEW_ID="@rpath/${DYLIB_NAME}.framework/${DYLIB_NAME}"
    install_name_tool \
        -id "${NEW_ID}" "${DYLIB}" \
        2> /dev/null

    # update dylib dep paths
    otool -l "${DYLIB}" |
        grep " name " |
        cut -d " " -f11 |
        tail -n +2 |
        grep "@rpath" |
        while read DEP; do
            DEP_NAME=$(basename $DEP .dylib | sed 's/\.[0-9]*$//' | sed 's/^lib//')
            DEP_NAME="$(tr '[:lower:]' '[:upper:]' <<< ${DEP_NAME:0:1})${DEP_NAME:1}"

            NEW_DEP="@rpath/${DEP_NAME}.framework/${DEP_NAME}"

            install_name_tool \
                -change "${DEP}" "${NEW_DEP}" \
                "${DYLIB}" \
                2>/dev/null
        done

    codesign --remove "${DYLIB}"

    # add Info.plist
    cp ./Scripts/Info.plist "${FRAMEWORKS_DIR}/${DYLIB_NAME}.framework/"
    sed -i '' 's/${FRAMEWORK_NAME}/'${DYLIB_NAME}'/g' "${FRAMEWORKS_DIR}/${DYLIB_NAME}.framework/Info.plist"
    sed -i '' 's/${MIN_OS_VERSION}/'${MIN_OS_VERSION}'/g' "${FRAMEWORKS_DIR}/${DYLIB_NAME}.framework/Info.plist"
    plutil -convert binary1 "${FRAMEWORKS_DIR}/${DYLIB_NAME}.framework/Info.plist"
done
