#if canImport(Flutter)
  import Flutter
#elseif canImport(FlutterMacOS)
  import FlutterMacOS
#endif

public class VideoOutputManager: NSObject {
  private let registry: FlutterTextureRegistry
  private var videoOutputs = [Int64: VideoOutput]()

  private let pipAvailable: Bool

  init(registry: FlutterTextureRegistry) {
    self.registry = registry

    // AVPictureInPictureController.ContentSource is available only since iOS 15+
    if #available(iOS 15.0, *) {
      pipAvailable = true
    } else {
      pipAvailable = false
    }

    super.init()
  }

  public func create(
    handle: Int64,
    configuration: VideoOutputConfiguration,
    textureUpdateCallback: @escaping VideoOutput.TextureUpdateCallback
  ) {
    #if os(iOS)
    if #available(iOS 15.0, *) {
      let videoOutput = VideoOutputWithPIP(
        handle: handle,
        configuration: configuration,
        registry: self.registry,
        textureUpdateCallback: textureUpdateCallback
      )
      self.videoOutputs[handle] = videoOutput
      
      return
    }
    #endif

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

  public func isPictureInPictureAvailable() -> Bool {
    return pipAvailable
  }

  public func enablePictureInPicture(
    handle: Int64
  ) -> Bool {
    let videoOutput = self.videoOutputs[handle]
    if videoOutput == nil {
      return false
    }

    return videoOutput!.enablePictureInPicture()
  }

  public func disablePictureInPicture(
    handle: Int64
  ) {
    let videoOutput = self.videoOutputs[handle]
    if videoOutput == nil {
      return
    }

    videoOutput!.disablePictureInPicture()
  }

  public func enableAutoPictureInPicture(
    handle: Int64
  ) -> Bool {
    let videoOutput = self.videoOutputs[handle]
    if videoOutput == nil {
      return false
    }

    return videoOutput!.enableAutoPictureInPicture()
  }

  public func disableAutoPictureInPicture(
    handle: Int64
  ) {
    let videoOutput = self.videoOutputs[handle]
    if videoOutput == nil {
      return
    }

    videoOutput!.disableAutoPictureInPicture()
  }

  public func enterPictureInPicture(
    handle: Int64
  ) -> Bool {
    let videoOutput = self.videoOutputs[handle]
    if videoOutput == nil {
      return false
    }

    return videoOutput!.enterPictureInPicture()
  }

  public func refreshPlaybackState(
    handle: Int64
  ) {
    let videoOutput = self.videoOutputs[handle]
    if videoOutput == nil {
      return
    }

    videoOutput!.refreshPlaybackState()
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
