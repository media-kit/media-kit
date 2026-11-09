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
    configuration: VideoOutputConfiguration,
    textureUpdateCallback: @escaping VideoOutput.TextureUpdateCallback
  ) {
    let videoOutput = VideoOutput(
      handle: handle,
      configuration: configuration,
      registry: self.registry,
      textureUpdateCallback: textureUpdateCallback
    )

    self.videoOutputs[handle] = videoOutput
  }

  public func setSize(
    handle: Int64,
    width: Int64?,
    height: Int64?
  ) {
    let videoOutput = self.videoOutputs[handle]
    if videoOutput == nil {
      return
    }

    videoOutput!.setSize(
      width: width,
      height: height
    )
  }

  // Completion runs on the main thread once the render context is freed and
  // the texture unregistered.
  public func destroy(
    handle: Int64,
    completion: @escaping () -> Void
  ) {
    let videoOutput = self.videoOutputs[handle]
    if videoOutput == nil {
      return completion()
    }

    self.videoOutputs[handle] = nil
    videoOutput!.dispose(completion)
  }
}
