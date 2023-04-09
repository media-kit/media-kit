#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint media_kit_video.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  # Setup required files
  system("make -C ../common/darwin HEADERS_DESTDIR=\"$(pwd)/Headers\"")

  # Find the nearest path to `pubspec.lock`
  current_dir       = ENV['PWD']
  pubspec_lock_path = ''
  while pubspec_lock_path == '' && current_dir != '/'
    path = File.join(current_dir, 'pubspec.lock')
    if File.exist?(path)
      pubspec_lock_path = path
    else
      current_dir = File.expand_path('..', current_dir)
    end
  end

  # Fail if no `pubspec.lock` was found
  if pubspec_lock_path == ''
    abort(
      sprintf('ERROR: No pubspec.lock was found: ENV["PWD"] = "%s"', ENV["PWD"])
    )
  end

  # Checks for `media_kit_libs_*` in `pubspec.lock`
  pubspec_lock           = YAML.load_file(pubspec_lock_path)
  packages               = pubspec_lock['packages']
  libs_audio_dep_found   = packages.keys.include?('media_kit_libs_ios_audio')
  libs_video_dep_found   = packages.keys.include?('media_kit_libs_ios_video')
  libs_dep_found         = libs_audio_dep_found || libs_video_dep_found

  # Warn if no `media_kit_libs_*` is found
  if !libs_dep_found
    warn("media_kit_video: WARNING: package:media_kit_libs_*** not found")
  end

  # Define paths to frameworks dir
  framework_search_paths_iphoneos        = ''
  framework_search_paths_iphonesimulator = ''
  if libs_audio_dep_found
    framework_search_paths_iphoneos        = '$(PROJECT_DIR)/../.symlinks/plugins/media_kit_libs_ios_audio/ios/Frameworks/MPV.xcframework/ios-arm64'
    framework_search_paths_iphonesimulator = '$(PROJECT_DIR)/../.symlinks/plugins/media_kit_libs_ios_audio/ios/Frameworks/MPV.xcframework/ios-arm64_x86_64-simulator'
  elsif libs_video_dep_found
    framework_search_paths_iphoneos        = '$(PROJECT_DIR)/../.symlinks/plugins/media_kit_libs_ios_video/ios/Frameworks/MPV.xcframework/ios-arm64'
    framework_search_paths_iphonesimulator = '$(PROJECT_DIR)/../.symlinks/plugins/media_kit_libs_ios_video/ios/Frameworks/MPV.xcframework/ios-arm64_x86_64-simulator'
  end

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
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'
  s.dependency         'Flutter'
  
  if libs_dep_found
    s.source_files        = 'Classes/plugin/**/*.swift', 'Headers/**/*.h'
    s.pod_target_xcconfig = {
      'DEFINES_MODULE'                               => 'YES',
      'GCC_WARN_INHIBIT_ALL_WARNINGS'                => 'YES',
      'GCC_PREPROCESSOR_DEFINITIONS'                 => '"$(inherited)" GL_SILENCE_DEPRECATION COREVIDEO_SILENCE_GL_DEPRECATION',
      'FRAMEWORK_SEARCH_PATHS[sdk=iphoneos*]'        => sprintf('"$(inherited)" "%s"', framework_search_paths_iphoneos),
      'FRAMEWORK_SEARCH_PATHS[sdk=iphonesimulator*]' => sprintf('"$(inherited)" "%s"', framework_search_paths_iphonesimulator),
      'OTHER_LDFLAGS'                                => '"$(inherited)" -framework Mpv',
      # Flutter.framework does not contain a i386 slice.
      'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    }
  else
    s.source_files        = 'Classes/stub/**/*.swift'
    s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  end
end
