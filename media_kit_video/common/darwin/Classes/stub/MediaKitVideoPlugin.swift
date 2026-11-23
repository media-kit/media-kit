#if canImport(Flutter)
  import Flutter
#elseif canImport(FlutterMacOS)
  import FlutterMacOS
#endif

// Keep the native API source-compatible when the optional video libraries are
// absent. No render context can be created by this implementation.
public enum VideoOutputRenderingResult {
  case unchanged
  case changed
  case notReady
  case failed
}

public class MediaKitVideoPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    registrar.publish(MediaKitVideoPlugin())
  }

  public func setSoftwareRendering(
    handle: Int64,
    enabled: Bool,
    completion: @escaping (VideoOutputRenderingResult) -> Void
  ) {
    completion(.failed)
  }

  public func setSoftwareRenderingForNewOutputs(_ enabled: Bool) {}

  public var softwareRenderingHandles: [Int64] { [] }
}
