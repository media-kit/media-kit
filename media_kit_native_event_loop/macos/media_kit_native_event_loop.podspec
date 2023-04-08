#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint media_kit_native_event_loop.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  # Setup required files
  system("make -C ../common/darwin")

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

  # Checks the presence of any `media_kit_libs_*` in `pubspec.lock`
  pubspec_lock           = YAML.load_file(pubspec_lock_path)
  packages               = pubspec_lock['packages']
  libs_audio_dep_found   = packages.keys.include?('media_kit_libs_macos_audio')
  libs_video_dep_found   = packages.keys.include?('media_kit_libs_macos_video')
  libs_dep_found         = libs_audio_dep_found || libs_video_dep_found

  # Define paths to frameworks dir
  framework_search_paths_macosx = ''
  if libs_audio_dep_found
    framework_search_paths_macosx = '$(PROJECT_DIR)/../Flutter/ephemeral/.symlinks/plugins/media_kit_libs_macos_audio/macos/Frameworks/MPV.xcframework/macos-arm64_x86_64'
  elsif libs_video_dep_found
    framework_search_paths_macosx = '$(PROJECT_DIR)/../Flutter/ephemeral/.symlinks/plugins/media_kit_libs_macos_video/macos/Frameworks/MPV.xcframework/macos-arm64_x86_64'
  end

  s.name             = 'media_kit_native_event_loop'
  s.version          = '1.0.0'
  s.summary          = 'Platform specific threaded event handling for media_kit.'
  s.description      = <<-DESC
  Platform specific threaded event handling for media_kit.
                       DESC
  s.homepage         = 'https://github.com/alexmercerind/media_kit.git'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Hitesh Kumar Saini' => 'saini123hitesh@gmail.com' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.dependency         'FlutterMacOS'

  if libs_dep_found
    s.source_files        = 'Classes/**/*'
    s.platform            = :osx, '11.0'
    s.swift_version       = '5.0'
    s.pod_target_xcconfig = {
      'DEFINES_MODULE'                      => 'YES',
      'GCC_WARN_INHIBIT_ALL_WARNINGS'       => 'YES',
      'HEADER_SEARCH_PATHS'                 => '"$(inherited)" "$(PROJECT_DIR)/../Flutter/ephemeral/.symlinks/plugins/media_kit_native_event_loop/common/darwin/Headers"',
      'FRAMEWORK_SEARCH_PATHS[sdk=macosx*]' => sprintf('"$(inherited)" "%s"', framework_search_paths_macosx),
      'OTHER_LDFLAGS'                       => '"$(inherited)" -framework Mpv',
    }
  end
end
