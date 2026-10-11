#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd "$(dirname "$0")" && pwd)"
plugin_dir="$script_dir/../../common/darwin/Classes/plugin"
build_dir="$(mktemp -d "${TMPDIR:-/tmp}/media-kit-rendering-test.XXXXXX")"
trap 'rm -rf "$build_dir"' EXIT
xcrun swiftc -module-cache-path "$build_dir/module-cache" \
  "$plugin_dir/VideoOutputConfiguration.swift" \
  "$plugin_dir/VideoOutputManager.swift" \
  "$script_dir/main.swift" -o "$build_dir/rendering-tests"
"$build_dir/rendering-tests"

xcrun swiftc -parse-as-library -module-cache-path "$build_dir/module-cache" \
  "$plugin_dir/VideoOutputConfiguration.swift" \
  "$plugin_dir/Worker.swift" \
  "$plugin_dir/VideoOutput.swift" \
  "$script_dir/output.swift" -o "$build_dir/output-tests"
"$build_dir/output-tests"
