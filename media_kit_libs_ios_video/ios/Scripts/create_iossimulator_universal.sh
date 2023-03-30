#!/bin/sh

mkdir -p .tmp/libs/libmpv-iossimulator-universal
find ".tmp/libs/libmpv-iossimulator-amd64" \
    -type f -name '*.dylib' \
    -exec \
    sh -c ' \
    lipo \
        -create \
        "{}" \
        $(echo "{}" | sed -r "s|amd64|arm64|g") \
        -output \
        $(echo "{}" | sed -r "s|amd64|universal|g") \
    ' \
\;
