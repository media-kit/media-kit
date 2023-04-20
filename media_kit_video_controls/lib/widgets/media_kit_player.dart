import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video_controls/widgets/widgets.dart';
import 'package:media_kit/media_kit.dart';

import 'package:wakelock/wakelock.dart';
import 'package:window_manager/window_manager.dart';

typedef MediaKitRoutePageBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  MediaKitControllerProvider controllerProvider,
);

/// A Video Player with Material and Cupertino skins.
///
/// `video_player` is pretty low level. MediaKitVideo wraps it in a friendly skin to
/// make it easy to use!
class MediaKitControls extends StatefulWidget {
  const MediaKitControls({
    Key? key,
    required this.controller,
    required this.video,
  }) : super(key: key);

  /// The [MediaKitController]
  final MediaKitController controller;

  /// The [Video Widget]
  final Widget video;
  @override
  MediaKitState createState() {
    return MediaKitState();
  }
}

class MediaKitState extends State<MediaKitControls> {
  bool _isFullScreen = false;

  bool get isControllerFullScreen => widget.controller.isFullScreen;
  PlayerNotifier? notifier;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(listener);
    notifier = PlayerNotifier.init();
  }

  @override
  void dispose() {
    widget.controller.removeListener(listener);
    super.dispose();
  }

  @override
  void didUpdateWidget(MediaKitControls oldWidget) {
    if (oldWidget.controller != widget.controller) {
      widget.controller.addListener(listener);
    }
    super.didUpdateWidget(oldWidget);
    if (_isFullScreen != isControllerFullScreen) {
      widget.controller._isFullScreen = _isFullScreen;
    }
  }

  Future<void> listener() async {
    if (isControllerFullScreen && !_isFullScreen) {
      _isFullScreen = isControllerFullScreen;
      await _pushFullScreenWidget(context);
    } else if (_isFullScreen) {
      Navigator.of(
        context,
        rootNavigator: widget.controller.useRootNavigator,
      ).pop();
      _isFullScreen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MediaKitControllerProvider(
      controller: widget.controller,
      child: PlayerNotifierProvider(
          notifier: notifier!, child: PlayerWithControls(video: widget.video)),
    );
  }

  Widget _buildFullScreenVideo(
    BuildContext context,
    Animation<double> animation,
    MediaKitControllerProvider controllerProvider,
  ) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        alignment: Alignment.center,
        color: Colors.black,
        child: controllerProvider,
      ),
    );
  }

  AnimatedWidget _defaultRoutePageBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    MediaKitControllerProvider controllerProvider,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        return _buildFullScreenVideo(context, animation, controllerProvider);
      },
    );
  }

  Widget _fullScreenRoutePageBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final controllerProvider = MediaKitControllerProvider(
      controller: widget.controller,
      child: PlayerNotifierProvider(
        notifier: notifier!,
        child: PlayerWithControls(
          video: widget.video,
        ),
      ),
    );

    if (widget.controller.routePageBuilder == null) {
      return _defaultRoutePageBuilder(
        context,
        animation,
        secondaryAnimation,
        controllerProvider,
      );
    }
    return widget.controller.routePageBuilder!(
      context,
      animation,
      secondaryAnimation,
      controllerProvider,
    );
  }

  Future<dynamic> _pushFullScreenWidget(BuildContext context) async {
    final TransitionRoute<void> route = PageRouteBuilder<void>(
      pageBuilder: _fullScreenRoutePageBuilder,
    );

    onEnterFullScreen();

    if (!widget.controller.allowedScreenSleep) {
      Wakelock.enable();
    }

    await Navigator.of(
      context,
      rootNavigator: widget.controller.useRootNavigator,
    ).push(route);
    _isFullScreen = false;
    widget.controller.exitFullScreen();

    // The wakelock plugins checks whether it needs to perform an action internally,
    // so we do not need to check Wakelock.isEnabled.
    Wakelock.disable();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: widget.controller.systemOverlaysAfterFullScreen,
    );
    SystemChrome.setPreferredOrientations(
      widget.controller.deviceOrientationsAfterFullScreen,
    );
  }

  void onEnterFullScreen() {
    final videoWidth = widget.controller.player.state.width ?? 0;
    final videoHeight = widget.controller.player.state.height ?? 0;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

    // if (widget.controller.systemOverlaysOnEnterFullScreen != null) {
    //   /// Optional user preferred settings
    //   SystemChrome.setEnabledSystemUIMode(
    //     SystemUiMode.manual,
    //     overlays: widget.controller.systemOverlaysOnEnterFullScreen,
    //   );
    // } else {
    //   /// Default behavior
    //   SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    // }

    if (widget.controller.deviceOrientationsOnEnterFullScreen != null) {
      /// Optional user preferred settings
      SystemChrome.setPreferredOrientations(
        widget.controller.deviceOrientationsOnEnterFullScreen!,
      );
    } else {
      final isLandscapeVideo = videoWidth > videoHeight;
      final isPortraitVideo = videoWidth < videoHeight;

      /// Default behavior
      /// Video w > h means we force landscape
      if (isLandscapeVideo) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }

      /// Video h > w means we force portrait
      else if (isPortraitVideo) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }

      /// Otherwise if h == w (square video)
      else {
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      }
    }
  }
}

/// The MediaKitController is used to configure and drive the MediaKitVideo Player
/// Widgets. It provides methods to control playback, such as [pause] and
/// [play], as well as methods that control the visual appearance of the player,
/// such as [enterFullScreen] or [exitFullScreen].
///
/// In addition, you can listen to the MediaKitController for presentational
/// changes, such as entering and exiting full screen mode. To listen for
/// changes to the playback, such as a change to the seek position of the
/// player, please use the standard information provided by the
/// `Player`.
class MediaKitController extends ChangeNotifier {
  MediaKitController({
    required this.player,
    this.optionsTranslation,
    this.autoInitialize = false,
    this.autoPlay = false,
    this.startAt,
    this.looping = false,
    this.fullScreenByDefault = false,
    this.cupertinoProgressColors,
    this.materialProgressColors,
    this.placeholder,
    this.overlay,
    this.showControlsOnInitialize = true,
    this.showOptions = true,
    this.optionsBuilder,
    this.additionalOptions,
    this.showControls = true,
    this.transformationController,
    this.zoomAndPan = false,
    this.maxScale = 2.5,
    this.subtitle,
    this.subtitleBuilder,
    this.customControls,
    this.errorBuilder,
    this.allowedScreenSleep = true,
    this.isLive = false,
    this.allowFullScreen = true,
    this.allowMuting = true,
    this.allowPlaybackSpeedChanging = true,
    this.useRootNavigator = true,
    this.playbackSpeeds = const [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2],
    this.systemOverlaysOnEnterFullScreen,
    this.deviceOrientationsOnEnterFullScreen,
    this.systemOverlaysAfterFullScreen = SystemUiOverlay.values,
    this.deviceOrientationsAfterFullScreen = DeviceOrientation.values,
    this.routePageBuilder,
    this.progressIndicatorDelay,
    this.hideControlsTimer = defaultHideControlsTimer,
    this.controlsSafeAreaMinimum = EdgeInsets.zero,
  }) : assert(
          playbackSpeeds.every((speed) => speed > 0),
          'The playbackSpeeds values must all be greater than 0',
        ) {
    _initialize();
  }

  MediaKitController copyWith({
    Player? player,
    OptionsTranslation? optionsTranslation,
    bool? autoInitialize,
    bool? autoPlay,
    Duration? startAt,
    bool? looping,
    bool? fullScreenByDefault,
    MediaKitProgressColors? cupertinoProgressColors,
    MediaKitProgressColors? materialProgressColors,
    Widget? placeholder,
    Widget? overlay,
    bool? showControlsOnInitialize,
    bool? showOptions,
    Future<void> Function(BuildContext, List<OptionItem>)? optionsBuilder,
    List<OptionItem> Function(BuildContext)? additionalOptions,
    bool? showControls,
    TransformationController? transformationController,
    bool? zoomAndPan,
    double? maxScale,
    Subtitles? subtitle,
    Widget Function(BuildContext, dynamic)? subtitleBuilder,
    Widget? customControls,
    Widget Function(BuildContext, String)? errorBuilder,
    bool? allowedScreenSleep,
    bool? isLive,
    bool? allowFullScreen,
    bool? allowMuting,
    bool? allowPlaybackSpeedChanging,
    bool? useRootNavigator,
    Duration? hideControlsTimer,
    EdgeInsets? controlsSafeAreaMinimum,
    List<double>? playbackSpeeds,
    List<SystemUiOverlay>? systemOverlaysOnEnterFullScreen,
    List<DeviceOrientation>? deviceOrientationsOnEnterFullScreen,
    List<SystemUiOverlay>? systemOverlaysAfterFullScreen,
    List<DeviceOrientation>? deviceOrientationsAfterFullScreen,
    Duration? progressIndicatorDelay,
    Widget Function(
      BuildContext,
      Animation<double>,
      Animation<double>,
      MediaKitControllerProvider,
    )?
        routePageBuilder,
  }) {
    return MediaKitController(
      player: player ?? this.player,
      optionsTranslation: optionsTranslation ?? this.optionsTranslation,
      autoInitialize: autoInitialize ?? this.autoInitialize,
      autoPlay: autoPlay ?? this.autoPlay,
      startAt: startAt ?? this.startAt,
      looping: looping ?? this.looping,
      fullScreenByDefault: fullScreenByDefault ?? this.fullScreenByDefault,
      cupertinoProgressColors:
          cupertinoProgressColors ?? this.cupertinoProgressColors,
      materialProgressColors:
          materialProgressColors ?? this.materialProgressColors,
      placeholder: placeholder ?? this.placeholder,
      overlay: overlay ?? this.overlay,
      showControlsOnInitialize:
          showControlsOnInitialize ?? this.showControlsOnInitialize,
      showOptions: showOptions ?? this.showOptions,
      optionsBuilder: optionsBuilder ?? this.optionsBuilder,
      additionalOptions: additionalOptions ?? this.additionalOptions,
      showControls: showControls ?? this.showControls,
      subtitle: subtitle ?? this.subtitle,
      subtitleBuilder: subtitleBuilder ?? this.subtitleBuilder,
      customControls: customControls ?? this.customControls,
      errorBuilder: errorBuilder ?? this.errorBuilder,
      allowedScreenSleep: allowedScreenSleep ?? this.allowedScreenSleep,
      isLive: isLive ?? this.isLive,
      allowFullScreen: allowFullScreen ?? this.allowFullScreen,
      allowMuting: allowMuting ?? this.allowMuting,
      allowPlaybackSpeedChanging:
          allowPlaybackSpeedChanging ?? this.allowPlaybackSpeedChanging,
      useRootNavigator: useRootNavigator ?? this.useRootNavigator,
      playbackSpeeds: playbackSpeeds ?? this.playbackSpeeds,
      systemOverlaysOnEnterFullScreen: systemOverlaysOnEnterFullScreen ??
          this.systemOverlaysOnEnterFullScreen,
      deviceOrientationsOnEnterFullScreen:
          deviceOrientationsOnEnterFullScreen ??
              this.deviceOrientationsOnEnterFullScreen,
      systemOverlaysAfterFullScreen:
          systemOverlaysAfterFullScreen ?? this.systemOverlaysAfterFullScreen,
      deviceOrientationsAfterFullScreen: deviceOrientationsAfterFullScreen ??
          this.deviceOrientationsAfterFullScreen,
      routePageBuilder: routePageBuilder ?? this.routePageBuilder,
      hideControlsTimer: hideControlsTimer ?? this.hideControlsTimer,
      progressIndicatorDelay:
          progressIndicatorDelay ?? this.progressIndicatorDelay,
    );
  }

  static const defaultHideControlsTimer = Duration(seconds: 3);

  /// If false, the options button in MaterialUI and MaterialDesktopUI
  /// won't be shown.
  final bool showOptions;

  /// Pass your translations for the options like:
  /// - PlaybackSpeed
  /// - Subtitles
  /// - Cancel
  ///
  /// Buttons
  ///
  /// These are required for the default `OptionItem`'s
  final OptionsTranslation? optionsTranslation;

  /// Build your own options with default mediaKitOptions shiped through
  /// the builder method. Just add your own options to the Widget
  /// you'll build. If you want to hide the mediaKitOptions, just leave them
  /// out from your Widget.
  final Future<void> Function(
    BuildContext context,
    List<OptionItem> mediaKitOptions,
  )? optionsBuilder;

  /// Add your own additional options on top of mediaKit options
  final List<OptionItem> Function(BuildContext context)? additionalOptions;

  /// Define here your own Widget on how your n'th subtitle will look like
  Widget Function(BuildContext context, dynamic subtitle)? subtitleBuilder;

  /// Add a List of Subtitles here in `Subtitles.subtitle`
  Subtitles? subtitle;

  /// The controller for the video you want to play
  final Player player;

  /// Initialize the Video on Startup. This will prep the video for playback.
  final bool autoInitialize;

  /// Play the video as soon as it's displayed
  final bool autoPlay;

  /// Start video at a certain position
  final Duration? startAt;

  /// Whether or not the video should loop
  final bool looping;

  /// Wether or not to show the controls when initializing the widget.
  final bool showControlsOnInitialize;

  /// Whether or not to show the controls at all
  final bool showControls;

  /// Controller to pass into the [InteractiveViewer] component
  final TransformationController? transformationController;

  /// Whether or not to allow zooming and panning
  final bool zoomAndPan;

  /// Max scale when zooming
  final double maxScale;

  /// Defines customised controls. Check [MaterialControls] or
  /// [CupertinoControls] for reference.
  final Widget? customControls;

  /// When the video playback runs into an error, you can build a custom
  /// error message.
  final Widget Function(BuildContext context, String errorMessage)?
      errorBuilder;

  /// The colors to use for controls on iOS. By default, the iOS player uses
  /// colors sampled from the original iOS 11 designs.
  final MediaKitProgressColors? cupertinoProgressColors;

  /// The colors to use for the Material Progress Bar. By default, the Material
  /// player uses the colors from your Theme.
  final MediaKitProgressColors? materialProgressColors;

  /// The placeholder is displayed underneath the Video before it is initialized
  /// or played.
  final Widget? placeholder;

  /// A widget which is placed between the video and the controls
  final Widget? overlay;

  /// Defines if the player will start in fullscreen when play is pressed
  final bool fullScreenByDefault;

  /// Defines if the player will sleep in fullscreen or not
  final bool allowedScreenSleep;

  /// Defines if the controls should be shown for live stream video
  final bool isLive;

  /// Defines if the fullscreen control should be shown
  final bool allowFullScreen;

  /// Defines if the mute control should be shown
  final bool allowMuting;

  /// Defines if the playback speed control should be shown
  final bool allowPlaybackSpeedChanging;

  /// Defines if push/pop navigations use the rootNavigator
  final bool useRootNavigator;

  /// Defines the [Duration] before the video controls are hidden. By default, this is set to three seconds.
  final Duration hideControlsTimer;

  /// Defines the set of allowed playback speeds user can change
  final List<double> playbackSpeeds;

  /// Defines the system overlays visible on entering fullscreen
  final List<SystemUiOverlay>? systemOverlaysOnEnterFullScreen;

  /// Defines the set of allowed device orientations on entering fullscreen
  final List<DeviceOrientation>? deviceOrientationsOnEnterFullScreen;

  /// Defines the system overlays visible after exiting fullscreen
  final List<SystemUiOverlay> systemOverlaysAfterFullScreen;

  /// Defines the set of allowed device orientations after exiting fullscreen
  final List<DeviceOrientation> deviceOrientationsAfterFullScreen;

  /// Defines a custom RoutePageBuilder for the fullscreen
  final MediaKitRoutePageBuilder? routePageBuilder;

  /// Defines a delay in milliseconds between entering buffering state and displaying the loading spinner. Set null (default) to disable it.
  final Duration? progressIndicatorDelay;

  /// Adds additional padding to the controls' [SafeArea] as desired.
  /// Defaults to [EdgeInsets.zero].
  final EdgeInsets controlsSafeAreaMinimum;

  static MediaKitController of(BuildContext context) {
    final mediaKitControllerProvider = context
        .dependOnInheritedWidgetOfExactType<MediaKitControllerProvider>()!;

    return mediaKitControllerProvider.controller;
  }

  bool _isFullScreen = false;

  bool get isFullScreen => _isFullScreen;

  bool _showingControls = false;

  bool get showingControls => _showingControls;

  bool get isPlaying => player.state.playing;

  bool playerIsNotInitialized() {
    return player.state.duration.inMicroseconds == 0;
  }

  StreamSubscription? fullScreenSubscription;
  Future _initialize() async {
    // await player.setLooping(looping);

    // if ((autoInitialize || autoPlay) &&
    //     playerIsNotInitialized()) {
    //   await player.initialize();
    // }

    if (autoPlay) {
      if (fullScreenByDefault) {
        enterFullScreen();
      }

      await player.play();
    }

    if (startAt != null) {
      await player.seek(startAt!);
    }

    if (fullScreenByDefault) {
      fullScreenSubscription = player.streams.playing.listen((event) {
        _fullScreenListener(event);
      });
    }
  }

  Future<void> _fullScreenListener(bool playing) async {
    if (playing && !_isFullScreen) {
      enterFullScreen();
      fullScreenSubscription?.cancel();
    }
  }

  void enterFullScreen() {
    _isFullScreen = true;
    notifyListeners();
  }

  void exitFullScreen() {
    _isFullScreen = false;
    notifyListeners();
  }

  void toggleFullScreen() {
    _isFullScreen = !_isFullScreen;
    if (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows) {
      Future.microtask(() async {
        await windowManager.ensureInitialized();

        await windowManager.setFullScreen(_isFullScreen);
      });
    }

    notifyListeners();
  }

  void togglePause() {
    isPlaying ? pause() : play();
  }

  Future<void> play() async {
    await player.play();
  }

  // // ignore: avoid_positional_boolean_parameters
  // Future<void> setLooping(bool looping) async {
  //   await player.setLooping(looping);
  // }

  Future<void> pause() async {
    await player.pause();
  }

  Future<void> seekTo(Duration moment) async {
    await player.seek(moment);
  }

  Future<void> setVolume(double volume) async {
    await player.setVolume(volume);
  }

  void setSubtitle(List<Subtitle> newSubtitle) {
    subtitle = Subtitles(newSubtitle);
  }
}

class MediaKitControllerProvider extends InheritedWidget {
  const MediaKitControllerProvider({
    Key? key,
    required this.controller,
    required Widget child,
  }) : super(key: key, child: child);

  final MediaKitController controller;

  @override
  bool updateShouldNotify(MediaKitControllerProvider oldWidget) =>
      controller != oldWidget.controller;
}
