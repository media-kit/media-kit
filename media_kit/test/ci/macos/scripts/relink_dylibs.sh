#!/bin/sh
set -e

# relink_dylibs updates the dependency paths of dynamic libraries by replacing a
# source prefix with a target prefix
relink_dylibs() {
    SOURCE_PREFIX=$1
    TARGET_PREFIX=$2
    DIR=$3

    find $DIR/*.dylib | while read DYLIB; do
        # change id of current dylib
        otool -l "$DYLIB" |
            grep " name " |
            cut -d " " -f11 |
            head -n +1 |
            while read ID; do
                NAME=$(basename $ID)

                echo "$DYLIB: $NAME"
                install_name_tool -id "@rpath/$NAME" "$DYLIB"
            done

        # change path of current dependencies
        otool -l "$DYLIB" |
            grep " name " |
            cut -d " " -f11 |
            tail -n +2 |
            grep "$SOURCE_PREFIX" |
            while read DEP; do
                DEPNAME=$(basename $DEP)

                echo "$DYLIB: $DEPNAME"
                install_name_tool -change "$DEP" \
                    "$TARGET_PREFIX/$DEPNAME" \
                    "$DYLIB" \
                    2>/dev/null
            done
    done
}

SOURCE_PREFIX=$1
TARGET_PREFIX=$2
DIR=$3

relink_dylibs "$SOURCE_PREFIX" "$TARGET_PREFIX" "$DIR"
