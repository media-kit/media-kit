#!/bin/sh

SOURCE_ARCHIVE="$1"
TARGET_FOLDER="$2"

# copy files
mkdir -p "${TARGET_FOLDER}/MPV.framework/Libs"
tar -xvf "${SOURCE_ARCHIVE}" --strip-components 1 -C "${TARGET_FOLDER}"/MPV.framework/Libs/

# mv mpv dylib
mv "${TARGET_FOLDER}"/MPV.framework/Libs/libmpv.dylib "${TARGET_FOLDER}"/MPV.framework/MPV

# update id & deb paths
find "${TARGET_FOLDER}" -type f | while read DYLIB; do
    echo "${DYLIB}"

    DYLIB_NAME=$(basename $DYLIB)

    codesign --force -s - "${DYLIB}"

    # update id
    otool -l "${DYLIB}" |
        grep " name " |
        cut -d " " -f11 |
        head -n +1 |
        while read ID; do
            NAME=$(basename $ID)

            if [ "${DYLIB_NAME}" = "MPV" ]; then
                NEW_ID=@rpath/MPV.framework/MPV
            else
                NEW_ID=@rpath/MPV.framework/Libs/"${NAME}"
            fi

            install_name_tool \
                -id "${NEW_ID}" "${DYLIB}" \
                2> /dev/null
        done

    # update dep paths
    otool -l "${DYLIB}" |
        grep " name " |
        cut -d " " -f11 |
        tail -n +2 |
        grep "@rpath" |
        while read DEP; do
            DEPNAME=$(basename $DEP)

            NEW_DEP=@rpath/MPV.framework/Libs/"${DEPNAME}"

            install_name_tool \
                -change "${DEP}" "${NEW_DEP}" \
                "${DYLIB}" \
                2>/dev/null
        done

    codesign --remove "${DYLIB}"
done
