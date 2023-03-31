#!/bin/sh

SOURCE_ARCHIVE="$1"
TARGET_FOLDER="$2"

# extract dylibs
mkdir -p "${TARGET_FOLDER}"
tar -xvf "${SOURCE_ARCHIVE}" --strip-components 1 -C "${TARGET_FOLDER}"

find "${TARGET_FOLDER}" -name "*.dylib" -type f | while read DYLIB; do
    echo "${DYLIB}"

    DYLIB_NAME=$(basename $DYLIB .dylib | sed 's/\.[0-9]*$//' | sed 's/^lib//')
    DYLIB_NAME="$(tr '[:lower:]' '[:upper:]' <<< ${DYLIB_NAME:0:1})${DYLIB_NAME:1}"

    # move dylib
    mkdir -p "${TARGET_FOLDER}/${DYLIB_NAME}.framework"
    mv "${DYLIB}" "${TARGET_FOLDER}/${DYLIB_NAME}.framework/${DYLIB_NAME}"

    DYLIB="${TARGET_FOLDER}/${DYLIB_NAME}.framework/${DYLIB_NAME}"

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
    cp ./Scripts/Info.plist "${TARGET_FOLDER}/${DYLIB_NAME}.framework/"
    sed -i '' 's/${FRAMEWORK_NAME}/'${DYLIB_NAME}'/g' "${TARGET_FOLDER}/${DYLIB_NAME}.framework/Info.plist"
    plutil -convert binary1 "${TARGET_FOLDER}/${DYLIB_NAME}.framework/Info.plist"
done
