#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint media_kit_video.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  system("make -C ../common/darwin HEADERS_DESTDIR=\"$(pwd)/Headers\"")

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
  s.source_files     = 'Classes/**/*.swift', 'Headers/**/*.h'
  s.dependency 'Flutter'
  
  s.platform = :ios, '13.0'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'GCC_WARN_INHIBIT_ALL_WARNINGS' => 'YES',
    'GCC_PREPROCESSOR_DEFINITIONS' => '"$(inherited)" GL_SILENCE_DEPRECATION COREVIDEO_SILENCE_GL_DEPRECATION',
    # Flutter.framework does not contain a i386 slice.
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    # # Uncomment the following three lines to activate the dynamic link
    # 'FRAMEWORK_SEARCH_PATHS[sdk=iphoneos*]' => '"$(inherited)" "$(PROJECT_DIR)/../.symlinks/plugins/media_kit_libs_ios_video/ios/Frameworks/MPV.xcframework/ios-arm64"',
    # 'FRAMEWORK_SEARCH_PATHS[sdk=iphonesimulator*]' => '"$(inherited)" "$(PROJECT_DIR)/../.symlinks/plugins/media_kit_libs_ios_video/ios/Frameworks/MPV.xcframework/ios-arm64_x86_64-simulator"',
    # 'OTHER_LDFLAGS' => '"$(inherited)" -framework Mpv',
  }
  s.swift_version = '5.0'
end
