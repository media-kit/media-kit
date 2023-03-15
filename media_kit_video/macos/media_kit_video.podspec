#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint media_kit_video.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  system("make")

  s.name             = 'media_kit_video'
  s.version          = '0.0.1'
  s.summary          = 'Native implementation for video playback in package:media_kit'
  s.description      = <<-DESC
  Native implementation for video playback in package:media_kit.
                       DESC
  s.homepage         = 'https://github.com/alexmercerind/media_kit.git'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Hitesh Kumar Saini' => 'saini123hitesh@gmail.com' }

  s.source           = { :path => '.' }
  s.source_files     =  "Classes/**/*.swift", "Headers/**/*.h"
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.13'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'GCC_WARN_INHIBIT_ALL_WARNINGS' => 'YES',
    'GCC_PREPROCESSOR_DEFINITIONS' => '"$(inherited)" GL_SILENCE_DEPRECATION COREVIDEO_SILENCE_GL_DEPRECATION',
    'LIBRARY_SEARCH_PATHS' => '"$(inherited)" "$(PROJECT_DIR)/../Flutter/ephemeral/.symlinks/plugins/media_kit_libs_macos_video/macos/Libs"',
    'OTHER_LDFLAGS' => '"$(inherited)" -lmpv',
  }
  s.swift_version = '5.0'
end
