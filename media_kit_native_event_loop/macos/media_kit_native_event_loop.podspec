#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint media_kit_native_event_loop.podspec` to validate before publishing.
#

require_relative '../common/darwin/Podspec/media_kit_utils.rb'

Pod::Spec.new do |s|
  # Setup required files
  system("make -C ../common/darwin")

  # Initialize `MediaKitUtils`
  mku = MediaKitUtils.new(MediaKitUtils::Platform::MACOS)

  s.name             = 'media_kit_native_event_loop'
  s.version          = '1.0.0'
  s.summary          = 'Platform specific threaded event handling for media_kit.'
  s.description      = <<-DESC
  Platform specific threaded event handling for media_kit.
                       DESC
  s.homepage         = 'https://github.com/media-kit/media-kit.git'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Hitesh Kumar Saini' => 'saini123hitesh@gmail.com' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.dependency         'FlutterMacOS'

  if mku.libs_found
    # Define paths to frameworks dir
    framework_search_paths_macosx = sprintf('$(PROJECT_DIR)/../Flutter/ephemeral/.symlinks/plugins/%s/macos/Frameworks/MPV.xcframework/macos-arm64_x86_64', mku.libs_package)

    s.source_files        = 'Classes/**/*'
    s.platform            = :osx, '10.9'
    s.swift_version       = '5.0'
    s.pod_target_xcconfig = {
      'DEFINES_MODULE'                      => 'YES',
      'GCC_WARN_INHIBIT_ALL_WARNINGS'       => 'YES',
      'HEADER_SEARCH_PATHS'                 => '"$(inherited)" "$(PROJECT_DIR)/../Flutter/ephemeral/.symlinks/plugins/media_kit_native_event_loop/common/darwin/Headers"',
      'FRAMEWORK_SEARCH_PATHS[sdk=macosx*]' => sprintf('"$(inherited)" "%s"', framework_search_paths_macosx),
      'OTHER_LDFLAGS'                       => '"$(inherited)" -framework Mpv -lpthread',
    }
  end
end
