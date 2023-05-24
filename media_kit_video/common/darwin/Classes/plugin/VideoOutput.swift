#if canImport(Flutter)
  import Flutter
#elseif canImport(FlutterMacOS)
  import FlutterMacOS
#endif

import AVKit

#if os(iOS)
import UIKit
#endif

// This class creates and manipulates the different types of FlutterTexture,
// handles resizing, rendering calls, and notify Flutter when a new frame is
// available to render.
//
// To improve the user experience, a worker is used to execute heavy tasks on a
// dedicated thread.
public class VideoOutput: NSObject {
  public typealias TextureUpdateCallback = (Int64, CGSize) -> Void

  private static let isSimulator: Bool = {
    let isSim: Bool
    #if targetEnvironment(simulator)
      isSim = true
    #else
      isSim = false
    #endif
    return isSim
  }()

  fileprivate let handle: OpaquePointer
  private let enableHardwareAcceleration: Bool
  private var usingHardwareAcceleration: Bool
  private let registry: FlutterTextureRegistry
  private let textureUpdateCallback: TextureUpdateCallback
  fileprivate let worker: Worker = .init()
  private var width: Int64?
  private var height: Int64?
  fileprivate var userSetWidth: Int64?
  fileprivate var userSetHeight: Int64?
  fileprivate var texture: ResizableTextureProtocol!
  private var textureId: Int64 = -1
  private var currentWidth: Int64 = 0
  private var currentHeight: Int64 = 0
  private var disposed: Bool = false

  init(
    handle: Int64,
    width: Int64?,
    height: Int64?,
    enableHardwareAcceleration: Bool,
    registry: FlutterTextureRegistry,
    textureUpdateCallback: @escaping TextureUpdateCallback
  ) {
    let handle = OpaquePointer(bitPattern: Int(handle))
    assert(handle != nil, "handle casting")

    self.handle = handle!
    self.width = width
    self.height = height
    self.enableHardwareAcceleration = VideoOutput.isSimulator ? false : enableHardwareAcceleration
    self.usingHardwareAcceleration = self.enableHardwareAcceleration
    self.registry = registry
    self.textureUpdateCallback = textureUpdateCallback

    super.init()
  
    worker.enqueue {
      self._init()
    }
  }
  
  public func switchToSoftwareRendering() {
    switchRendering(allowHardwareAcceleration: false)
  }
  
  public func switchToHardwareRendering() {
    switchRendering(allowHardwareAcceleration: true)
  }

  public func switchRendering(allowHardwareAcceleration: Bool) {
    if !enableHardwareAcceleration || allowHardwareAcceleration == usingHardwareAcceleration {
      return
    }
    
    usingHardwareAcceleration = allowHardwareAcceleration

    NSLog("switchRendering allowHardwareAcceleration: \(allowHardwareAcceleration)")
    let vid = mpv_get_property_string(handle, "vid")
    mpv_set_property_string(handle, "vid", "no")

    texture.dispose()
    disposeTextureId()
    currentWidth = 0
    currentHeight = 0
    _init(allowHardwareAcceleration: allowHardwareAcceleration)

    mpv_set_property_string(handle, "vid", vid)
  }

  public func setSize(width: Int64?, height: Int64?) {
    worker.enqueue {
      self.userSetWidth = width
      self.userSetHeight = height
      self._setTextureSize(width: width, height: height)
    }
  }

  public func _setTextureSize(width: Int64?, height: Int64?) {
    self.width = width
    self.height = height
  }
  
  public func refreshPlaybackState() {}

  func enablePictureInPicture() -> Bool {
    return false
  }
  
  public func disablePictureInPicture() {}

  public func enableAutoPictureInPicture() -> Bool {
    return false
  }

  public func disableAutoPictureInPicture() {}
  
  public func enterPictureInPicture() -> Bool {
    return false
  }
  

  public func dispose() {
    worker.enqueue {
      self._dispose()
    }
  }

  private func _dispose() {
    disposed = true

    disposeTextureId()
    texture.dispose()
  }

  private func _init(allowHardwareAcceleration: Bool = true) {
    NSLog(
      "VideoOutput: enableHardwareAcceleration: \(enableHardwareAcceleration) allowHardwareAcceleration: \(allowHardwareAcceleration)"
    )

    if VideoOutput.isSimulator {
      NSLog(
        "VideoOutput: warning: hardware rendering is disabled in the iOS simulator, due to an incompatibility with OpenGL ES"
      )
    }

    if enableHardwareAcceleration && allowHardwareAcceleration {
      texture = SafeResizableTexture(
        TextureHW(
          handle: handle,
          updateCallback: updateCallback
        )
      )
    } else {
      texture = SafeResizableTexture(
        TextureSW(
          handle: handle,
          updateCallback: updateCallback
        )
      )
    }

    textureId = registry.register(texture)
    textureUpdateCallback(textureId, CGSize(width: 0, height: 0))
  }

  private func disposeTextureId() {
    registry.unregisterTexture(textureId)
    textureId = -1
  }

  public func updateCallback() {
    worker.enqueue {
      self._updateCallback()
    }
  }

  fileprivate func _updateCallback() {
    let width = videoWidth
    let height = videoHeight

    let size = CGSize(
      width: Double(width),
      height: Double(height)
    )

    if currentWidth != width || currentHeight != height {
      currentWidth = width
      currentHeight = height

      texture.resize(size)
      textureUpdateCallback(textureId, size)
    }

    if width == 0 || height == 0 {
      return
    }

    if disposed {
      return
    }

    texture.render(size)

    registry.textureFrameAvailable(textureId)
  }

  private var videoWidth: Int64 {
    // fixed width
    if self.width != nil {
      return self.width!
    }

    var width: Int64 = 0
    mpv_get_property(handle, "width", MPV_FORMAT_INT64, &width)

    return width
  }

  private var videoHeight: Int64 {
    // fixed height
    if self.height != nil {
      return self.height!
    }

    var height: Int64 = 0
    mpv_get_property(handle, "height", MPV_FORMAT_INT64, &height)

    return height
  }
}

#if os(iOS)
@available(iOS 15.0, *)
public class VideoOutputWithPIP: VideoOutput, AVPictureInPictureSampleBufferPlaybackDelegate, AVPictureInPictureControllerDelegate {
  private var bufferDisplayLayer: AVSampleBufferDisplayLayer = AVSampleBufferDisplayLayer()
  private var pipController: AVPictureInPictureController? = nil
  private var videoFormat: CMVideoFormatDescription? = nil
  private var notificationCenter: NotificationCenter {
      return .default
  }
  
  override init(handle: Int64, width: Int64?, height: Int64?, enableHardwareAcceleration: Bool, registry: FlutterTextureRegistry, textureUpdateCallback: @escaping VideoOutput.TextureUpdateCallback) {
    super.init(handle: handle, width: width, height: height, enableHardwareAcceleration: enableHardwareAcceleration, registry: registry, textureUpdateCallback: textureUpdateCallback)
    
    notificationCenter.addObserver(self, selector: #selector(appWillResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
    notificationCenter.addObserver(self, selector: #selector(appWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
  }
  
  deinit {
    notificationCenter.removeObserver(self)
  }
  
  @objc private func appWillEnterForeground(_ notification: NSNotification) {
    worker.enqueue {
      self.switchToHardwareRendering()
    }
  }
  
  @objc private func appWillResignActive(_ notification: NSNotification) {
    if pipController == nil {
      return
    }
    
    if pipController!.canStartPictureInPictureAutomaticallyFromInline || pipController!.isPictureInPictureActive {
      switchToSoftwareRendering()
      return
    }
    
    var isPaused: Int8 = 0
    mpv_get_property(handle, "pause", MPV_FORMAT_FLAG, &isPaused)
    
    if isPaused == 1 {
      return
    }
    
    // Pause if apps goes into background and PiP is not enabled.
    // Otherwise audio and video will continue playing.
    mpv_command_string(handle, "cycle pause")
  }
  
  override public func refreshPlaybackState() {
    pipController?.invalidatePlaybackState()
  }
  
  override public func enablePictureInPicture() -> Bool {
    if pipController != nil {
      return true
    }
    
    bufferDisplayLayer.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
    bufferDisplayLayer.opacity = 0
    bufferDisplayLayer.videoGravity = .resizeAspect
    
    let contentSource = AVPictureInPictureController.ContentSource(sampleBufferDisplayLayer: bufferDisplayLayer, playbackDelegate: self)
    pipController = AVPictureInPictureController(contentSource: contentSource)
    pipController!.delegate = self
    
    // keyWindow is deprecated but currently flutter uses it internally just as well.
    // See Flutter issue: https://github.com/flutter/flutter/issues/104117
    let controller = UIApplication.shared.keyWindow?.rootViewController
    // Add bufferDisplayLayer as an invisible layer to view to make PIP work.
    controller?.view.layer.addSublayer(bufferDisplayLayer)
    
    return true
  }
  
  override public func disablePictureInPicture() {
    if bufferDisplayLayer.superlayer != nil {
      bufferDisplayLayer.removeFromSuperlayer()
    }
    
    pipController = nil
  }
  
  override public func enableAutoPictureInPicture() -> Bool {
#if os(iOS)
    if enablePictureInPicture() {
      pipController?.canStartPictureInPictureAutomaticallyFromInline = true
      return true
    }
#endif
    
    return false
  }
  
  override public func disableAutoPictureInPicture() {
#if os(iOS)
    if pipController != nil {
      pipController?.canStartPictureInPictureAutomaticallyFromInline = false
    }
#endif
  }
  
  override public func enterPictureInPicture() -> Bool {
    if enablePictureInPicture() {
      pipController?.startPictureInPicture()
      return true
    }
    
    return false
  }
  
  override func _updateCallback() {
    super._updateCallback()
    
    if pipController != nil {
      let pixelBuffer = texture.copyPixelBuffer()?.takeUnretainedValue()
      if pixelBuffer == nil {
        return
      }
      
      var sampleBuffer: CMSampleBuffer?
      
      if videoFormat == nil || !CMVideoFormatDescriptionMatchesImageBuffer(videoFormat!, imageBuffer: pixelBuffer!)  {
        videoFormat = nil
        
        let err = CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer!, formatDescriptionOut: &videoFormat)
        if (err != noErr) {
          NSLog("Error at CMVideoFormatDescriptionCreateForImageBuffer \(err)")
        }
      }
      
      var sampleTimingInfo = CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: CMTime(seconds: CACurrentMediaTime(), preferredTimescale: 100), decodeTimeStamp: .invalid)
      
      let err = CMSampleBufferCreateForImageBuffer(allocator: nil, imageBuffer: pixelBuffer!, dataReady: true, makeDataReadyCallback: nil, refcon: nil, formatDescription: videoFormat!, sampleTiming: &sampleTimingInfo, sampleBufferOut: &sampleBuffer)
      if err == noErr {
        bufferDisplayLayer.enqueue(sampleBuffer!)
      } else {
        NSLog("Error at CMSampleBufferCreateForImageBuffer \(err)")
      }
    }
  }
  
  public override func dispose() {
    super.dispose()
    disablePictureInPicture()
  }

  public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {
    var isPaused: Int8 = 0
    mpv_get_property(handle, "pause", MPV_FORMAT_FLAG, &isPaused)
    
    if playing == (isPaused == 0) {
      return
    }

    mpv_command_string(handle, "cycle pause")
  }

  public func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
    var position: Double = 0
    mpv_get_property(handle, "time-pos", MPV_FORMAT_DOUBLE, &position)

    var duration: Double = 0
    mpv_get_property(handle, "duration", MPV_FORMAT_DOUBLE, &duration)
    
    return CMTimeRange(
      start:  CMTime(
        seconds: CACurrentMediaTime() - position,
        preferredTimescale: 100
      ),
      duration: CMTime(
        seconds: duration,
        preferredTimescale: 100
      )
    )
  }

  public func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
    var isPaused: Int8 = 0
    mpv_get_property(handle, "pause", MPV_FORMAT_FLAG, &isPaused)
    
    return isPaused == 1
  }

  public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, didTransitionToRenderSize newRenderSize: CMVideoDimensions) {
    NSLog("Resize texture due to PIP new size: \(newRenderSize)")

    worker.enqueue {
      if newRenderSize.width == 0 || newRenderSize.height == 0 {
        self._setTextureSize(width: nil, height: nil)
      } else {
        self._setTextureSize(width: Int64(CGFloat(newRenderSize.width) * UIScreen.main.scale),
                             height: Int64(CGFloat(newRenderSize.height) * UIScreen.main.scale))
      }
    }
  }

  public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, skipByInterval skipInterval: CMTime, completion completionHandler: @escaping () -> Void) {
    mpv_command_string(handle, "seek \(skipInterval.seconds)")
    completionHandler()
  }

  public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
    NSLog("pictureInPictureController error: \(error)")
  }
  
  public func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    self.setSize(width: userSetWidth, height: userSetHeight)
  }
}
#endif
