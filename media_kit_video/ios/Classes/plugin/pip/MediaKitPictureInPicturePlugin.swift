#if canImport(Flutter)
  import AVFoundation
  import AVKit
  import Flutter
  import UIKit

  /// Flutter plugin that exposes Picture-in-Picture controls to Dart through
  /// the `com.alexmercerind/media_kit_video/pip` method and event channels.
  ///
  /// The plugin is instantiated by `MediaKitVideoPlugin.register(with:)` and
  /// receives a direct reference to the `VideoOutputManager`, so no singleton
  /// access is required.
  final class MediaKitPictureInPicturePlugin: NSObject, FlutterStreamHandler {
    static let METHOD_CHANNEL = "com.alexmercerind/media_kit_video/pip"
    static let EVENT_CHANNEL = "com.alexmercerind/media_kit_video/pip/events"

    private let outputManager: VideoOutputManager
    private var controllerBox: AnyObject?
    private var eventSink: FlutterEventSink?
    private var audioSessionConfigured: Bool = false

    init(
      registrar: FlutterPluginRegistrar,
      outputManager: VideoOutputManager
    ) {
      self.outputManager = outputManager
      super.init()

      let messenger = registrar.messenger()
      let methodChannel = FlutterMethodChannel(
        name: Self.METHOD_CHANNEL,
        binaryMessenger: messenger
      )
      let eventChannel = FlutterEventChannel(
        name: Self.EVENT_CHANNEL,
        binaryMessenger: messenger
      )
      methodChannel.setMethodCallHandler { [weak self] call, result in
        self?.handle(call, result: result)
      }
      eventChannel.setStreamHandler(self)
    }

    // MARK: - Method channel

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      switch call.method {
      case "isSupported":
        if #available(iOS 15.0, *) {
          result(AVPictureInPictureController.isPictureInPictureSupported())
        } else {
          result(false)
        }
      case "isActive":
        if #available(iOS 15.0, *),
          let controller = controllerBox as? MediaKitPictureInPictureController
        {
          result(controller.isActive)
        } else {
          result(false)
        }
      case "start":
        handleStart(call.arguments, result: result)
      case "stop":
        if #available(iOS 15.0, *),
          let controller = controllerBox as? MediaKitPictureInPictureController
        {
          controller.stop()
        }
        controllerBox = nil
        result(nil)
      case "setAutoEnter":
        guard let args = call.arguments as? [String: Any],
          let enabled = args["enabled"] as? Bool
        else {
          result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
          return
        }
        if #available(iOS 15.0, *),
          let controller = controllerBox as? MediaKitPictureInPictureController
        {
          controller.setAutoEnter(enabled)
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    private func handleStart(_ arguments: Any?, result: @escaping FlutterResult) {
      guard #available(iOS 15.0, *) else {
        result(
          FlutterError(
            code: "UNSUPPORTED",
            message: "Picture-in-Picture requires iOS 15+",
            details: nil
          )
        )
        return
      }
      guard let args = arguments as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGS", message: "arguments required", details: nil))
        return
      }
      let handle = Self.readHandle(args["handle"])
      guard let handle = handle else {
        result(FlutterError(code: "INVALID_ARGS", message: "handle required", details: nil))
        return
      }
      let width = (args["width"] as? NSNumber)?.doubleValue ?? 1280
      let height = (args["height"] as? NSNumber)?.doubleValue ?? 720
      let autoEnter = args["autoEnter"] as? Bool ?? true
      let startImmediately = args["startImmediately"] as? Bool ?? false

      guard let hostView = Self.resolveHostView() else {
        result(
          FlutterError(
            code: "NO_WINDOW",
            message: "No host window available",
            details: nil
          )
        )
        return
      }

      configureAudioSessionIfNeeded()

      (controllerBox as? MediaKitPictureInPictureController)?.stop()
      let pipController = MediaKitPictureInPictureController(
        hostView: hostView,
        outputManager: outputManager,
        videoSize: CGSize(width: width, height: height)
      ) { [weak self] event in
        self?.eventSink?(event)
      }
      self.controllerBox = pipController

      let started = pipController.start(
        handle: handle,
        autoEnter: autoEnter,
        startImmediately: startImmediately
      )
      if started {
        result(nil)
      } else {
        self.controllerBox = nil
        result(
          FlutterError(
            code: "START_FAILED",
            message: "Unable to attach Picture-in-Picture pipeline",
            details: nil
          )
        )
      }
    }

    // MARK: - Audio session

    private func configureAudioSessionIfNeeded() {
      guard !audioSessionConfigured else { return }
      let session = AVAudioSession.sharedInstance()
      do {
        try session.setCategory(
          .playback,
          mode: .moviePlayback,
          options: [.allowAirPlay, .allowBluetoothA2DP]
        )
        try session.setActive(true)
        audioSessionConfigured = true
      } catch {
        NSLog("MediaKitPictureInPicturePlugin: AVAudioSession setup failed: \(error)")
      }
    }

    // MARK: - Helpers

    private static func readHandle(_ raw: Any?) -> Int64? {
      if let number = raw as? NSNumber { return number.int64Value }
      if let string = raw as? String { return Int64(string) }
      return nil
    }

    private static func resolveHostView() -> UIView? {
      for scene in UIApplication.shared.connectedScenes {
        guard let windowScene = scene as? UIWindowScene,
          scene.activationState == .foregroundActive
            || scene.activationState == .foregroundInactive
        else { continue }
        let keyed =
          windowScene.windows.first(where: { $0.isKeyWindow })
          ?? windowScene.windows.first
        if let window = keyed {
          return window.rootViewController?.view ?? window
        }
      }
      return nil
    }

    // MARK: - FlutterStreamHandler

    func onListen(
      withArguments arguments: Any?,
      eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
      eventSink = events
      return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
      eventSink = nil
      return nil
    }
  }
#endif
