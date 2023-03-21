#if canImport(Flutter)
  import Flutter
#elseif canImport(FlutterMacOS)
  import FlutterMacOS
#endif

// This class creates and manipulates the different types of FlutterTexture,
// handles resizing, rendering calls, and notify Flutter when a new frame is
// available to render.
//
// To improve the user experience, a worker is used to execute heavy tasks on a
// dedicated thread.
public class VideoOutput: NSObject {
  public typealias TextureUpdateCallback = (Int64, CGSize) -> Void

  private let handle: OpaquePointer
  private let width: Int64?
  private let height: Int64?
  private let enableHardwareAcceleration: Bool
  private let registry: FlutterTextureRegistry
  private let textureUpdateCallback: TextureUpdateCallback
  private let worker: Worker = Worker()
  private var texture: ResizableTextureProtocol!
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
    self.enableHardwareAcceleration = enableHardwareAcceleration
    self.registry = registry
    self.textureUpdateCallback = textureUpdateCallback

    super.init()

    worker.enqueue {
      self._init()
    }
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

  private func _init() {
    NSLog(
      "VideoOutput: enableHardwareAcceleration: \(enableHardwareAcceleration)"
    )
    if enableHardwareAcceleration {
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

  private func _updateCallback() {
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

    if self.disposed {
      return
    }

    self.texture.render(size)
    self.registry.textureFrameAvailable(self.textureId)
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
