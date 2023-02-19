#!/bin/sh

# relink_dylibs updates the dependency paths of dynamic libraries by replacing a
# source prefix with a target prefix
relink_dylibs() {
    SOURCE_PREFIX=$1
    TARGET_PREFIX=$2
    DIR=$3

    find $DIR/*.dylib | while read DYLIB
    do
        otool -l "$DYLIB" \
            | grep "name " \
            | grep "$SOURCE_PREFIX" \
            | cut -d " " -f11 \
            | while read DEP
        do
            DEPNAME=$(basename $DEP)

            echo "$DYLIB: $DEPNAME"
            install_name_tool -change "$DEP" \
                "$TARGET_PREFIX/$DEPNAME" \
                "$DYLIB" \
                2> /dev/null
        done
    done
}

SOURCE_PREFIX="@rpath/"
TARGET_PREFIX="@executable_path/../Frameworks/media_kit_libs_macos.framework/Resources/Resources.bundle/Contents/Resources"
DIR=$1

relink_dylibs "$SOURCE_PREFIX" "$TARGET_PREFIX" "$DIR"
