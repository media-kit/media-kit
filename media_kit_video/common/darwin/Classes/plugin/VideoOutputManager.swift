#if canImport(Flutter)
  import Flutter
#elseif canImport(FlutterMacOS)
  import FlutterMacOS
#endif

public class VideoOutputManager: NSObject {
  private let registry: FlutterTextureRegistry
  private var videoOutputs = [Int64: VideoOutput]()

  init(registry: FlutterTextureRegistry) {
    self.registry = registry
  }

  public func create(
    handle: Int64,
    width: Int64?,
    height: Int64?,
    enableHardwareAcceleration: Bool,
    textureUpdateCallback: @escaping VideoOutput.TextureUpdateCallback
  ) {
    let videoOutput = VideoOutput(
      handle: handle,
      width: width,
      height: height,
      enableHardwareAcceleration: enableHardwareAcceleration,
      registry: self.registry,
      textureUpdateCallback: textureUpdateCallback
    )

    self.videoOutputs[handle] = videoOutput
  }

  public func destroy(
    handle: Int64
  ) {
    let videoOutput = self.videoOutputs[handle]
    if videoOutput == nil {
      return
    }

    videoOutput!.dispose()
    self.videoOutputs[handle] = nil
  }
}
