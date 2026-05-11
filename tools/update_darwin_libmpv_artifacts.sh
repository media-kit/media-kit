#!/usr/bin/env bash
set -euo pipefail

REPO="media-kit/libmpv-darwin-build"
DRY_RUN=0
VERSION="v0.7.0"
VERSION_SET=0

usage() {
  cat <<'EOF'
Usage:
  tools/update_darwin_libmpv_artifacts.sh [version] [--dry-run] [--repo=<owner/name>]

Example:
  tools/update_darwin_libmpv_artifacts.sh
  tools/update_darwin_libmpv_artifacts.sh v0.7.0

The script reads GitHub release asset digests and updates Darwin libmpv artifact
versions/checksums. Existing CocoaPods Makefiles use .tar.gz assets. Future
SwiftPM Package.swift files, when present, use .zip binaryTarget assets.
EOF
}

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=1
      ;;
    --repo=*)
      REPO="${arg#--repo=}"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    v*)
      if [[ "$VERSION_SET" -eq 1 ]]; then
        usage
        exit 64
      fi
      VERSION="$arg"
      VERSION_SET=1
      ;;
    *)
      usage
      exit 64
      ;;
  esac
done

RELEASE_JSON="$(mktemp "${TMPDIR:-/tmp}/media-kit-release.XXXXXX.json")"
trap 'rm -f "$RELEASE_JSON"' EXIT

curl -fsSL \
  -H "Accept: application/vnd.github+json" \
  -H "User-Agent: media-kit-artifact-updater" \
  "https://api.github.com/repos/${REPO}/releases/tags/${VERSION}" \
  -o "$RELEASE_JSON"

digest_for() {
  local asset_name="$1"

  RELEASE_JSON="$RELEASE_JSON" ASSET_NAME="$asset_name" ruby -rjson -e '
    release = JSON.parse(File.read(ENV.fetch("RELEASE_JSON")))
    name = ENV.fetch("ASSET_NAME")
    asset = release.fetch("assets").find { |item| item["name"] == name }

    abort("Asset #{name} was not found in the release.") unless asset

    digest = asset["digest"]
    unless digest.is_a?(String) && digest.start_with?("sha256:")
      abort("Asset #{name} does not have a sha256 digest.")
    end

    puts digest.sub(/\Asha256:/, "")
  '
}

update_makefile() {
  local path="$1"
  local version="$2"
  local checksum="$3"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "Would update ${path}"
    return
  fi

  FILE_PATH="$path" VERSION="$version" CHECKSUM="$checksum" ruby -e '
    path = ENV.fetch("FILE_PATH")
    version = ENV.fetch("VERSION")
    checksum = ENV.fetch("CHECKSUM")
    contents = File.read(path)

    unless contents.sub!(/^MPV_XCFRAMEWORKS_VERSION=.*$/, "MPV_XCFRAMEWORKS_VERSION=#{version}")
      abort("MPV_XCFRAMEWORKS_VERSION was not found in #{path}")
    end

    unless contents.sub!(/^MPV_XCFRAMEWORKS_SHA256SUM=.*$/, "MPV_XCFRAMEWORKS_SHA256SUM=#{checksum}")
      abort("MPV_XCFRAMEWORKS_SHA256SUM was not found in #{path}")
    end

    File.write(path, contents)
  '
}

update_package_swift() {
  local path="$1"
  local platform="$2"
  local variant="$3"
  local flavor="$4"
  shift 4
  local frameworks=("$@")
  local artifact_base="https://github.com/${REPO}/releases/download/${VERSION}/libmpv-xcframeworks_${VERSION}_${platform}-universal-${variant}-${flavor}"

  [[ -f "$path" ]] || return

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "Would update ${path}"
  else
    FILE_PATH="$path" ARTIFACT_BASE="$artifact_base" ruby -e '
      path = ENV.fetch("FILE_PATH")
      artifact_base = ENV.fetch("ARTIFACT_BASE")
      contents = File.read(path)

      unless contents.sub!(/^let libmpvArtifactBase = ".*"$/, "let libmpvArtifactBase = \"#{artifact_base}\"")
        abort("libmpvArtifactBase was not found in #{path}")
      end

      File.write(path, contents)
    '
  fi

  for framework in "${frameworks[@]}"; do
    local zip_name="libmpv-xcframeworks_${VERSION}_${platform}-universal-${variant}-${flavor}_${framework}.zip"
    local checksum
    checksum="$(digest_for "$zip_name")"

    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "Would update ${framework}: ${checksum}"
    else
      FILE_PATH="$path" FRAMEWORK="$framework" CHECKSUM="$checksum" ruby -e '
        path = ENV.fetch("FILE_PATH")
        framework = ENV.fetch("FRAMEWORK")
        checksum = ENV.fetch("CHECKSUM")
        contents = File.read(path)
        pattern = /^(\s*"#{Regexp.escape(framework)}":\s*")[^"]+(".*)$/

        unless contents.sub!(pattern, "\\1#{checksum}\\2")
          abort("Checksum for #{framework} was not found in #{path}")
        end

        File.write(path, contents)
      '
    fi
  done
}

update_artifact() {
  local label="$1"
  local platform="$2"
  local variant="$3"
  local flavor="$4"
  local makefile_path="$5"
  local package_path="$6"

  local tar_name="libmpv-xcframeworks_${VERSION}_${platform}-universal-${variant}-${flavor}.tar.gz"
  local tar_checksum
  tar_checksum="$(digest_for "$tar_name")"

  update_makefile "$makefile_path" "$VERSION" "$tar_checksum"

  if [[ -f "$package_path" ]]; then
    shift 6
    update_package_swift "$package_path" "$platform" "$variant" "$flavor" "$@"
  fi

  echo "${label}: ${tar_checksum}"
}

update_artifact \
  "iOS audio" \
  "ios" \
  "audio" \
  "default" \
  "libs/ios/media_kit_libs_ios_audio/ios/Makefile" \
  "libs/ios/media_kit_libs_ios_audio/ios/media_kit_libs_ios_audio/Package.swift" \
  "Avcodec" \
  "Avfilter" \
  "Avformat" \
  "Avutil" \
  "Mbedcrypto" \
  "Mbedtls" \
  "Mbedx509" \
  "Mpv" \
  "Swresample" \
  "Swscale"

update_artifact \
  "iOS video" \
  "ios" \
  "video" \
  "default" \
  "libs/ios/media_kit_libs_ios_video/ios/Makefile" \
  "libs/ios/media_kit_libs_ios_video/ios/media_kit_libs_ios_video/Package.swift" \
  "Ass" \
  "Avcodec" \
  "Avfilter" \
  "Avformat" \
  "Avutil" \
  "Dav1d" \
  "Freetype" \
  "Fribidi" \
  "Harfbuzz" \
  "Mbedcrypto" \
  "Mbedtls" \
  "Mbedx509" \
  "Mpv" \
  "Png16" \
  "Swresample" \
  "Swscale" \
  "Uchardet" \
  "Xml2"

update_artifact \
  "macOS audio" \
  "macos" \
  "audio" \
  "full" \
  "libs/macos/media_kit_libs_macos_audio/macos/Makefile" \
  "libs/macos/media_kit_libs_macos_audio/macos/media_kit_libs_macos_audio/Package.swift" \
  "Avcodec" \
  "Avfilter" \
  "Avformat" \
  "Avutil" \
  "Mbedcrypto" \
  "Mbedtls" \
  "Mbedx509" \
  "Mpv" \
  "Swresample" \
  "Swscale"

update_artifact \
  "macOS video" \
  "macos" \
  "video" \
  "default" \
  "libs/macos/media_kit_libs_macos_video/macos/Makefile" \
  "libs/macos/media_kit_libs_macos_video/macos/media_kit_libs_macos_video/Package.swift" \
  "Ass" \
  "Avcodec" \
  "Avfilter" \
  "Avformat" \
  "Avutil" \
  "Dav1d" \
  "Freetype" \
  "Fribidi" \
  "Harfbuzz" \
  "Mbedcrypto" \
  "Mbedtls" \
  "Mbedx509" \
  "Mpv" \
  "Png16" \
  "Swresample" \
  "Swscale" \
  "Uchardet" \
  "Xml2"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Dry run completed. No files were changed."
fi
