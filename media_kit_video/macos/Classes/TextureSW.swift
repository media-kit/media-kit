import Cocoa
import FlutterMacOS

public class TextureSW: NSObject, FlutterTexture, ResizableTextureProtocol {
  public typealias UpdateCallback = () -> Void

  private let handle: OpaquePointer
  private let updateCallback: UpdateCallback
  private var renderContext: OpaquePointer?
  private var pixelBuffer: CVPixelBuffer?

  init(
    handle: OpaquePointer,
    updateCallback: @escaping UpdateCallback
  ) {
    self.handle = handle
    self.updateCallback = updateCallback

    super.init()

    DispatchQueue.main.async {
      self.initMPV()
    }
  }

  public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
    if pixelBuffer == nil {
      return nil
    }

    return Unmanaged.passRetained(pixelBuffer!)
  }

  public func dispose() {
    disposePixelBuffer()
    disposeMPV()
  }

  private func initMPV() {
    MPVHelpers.checkError(mpv_set_option_string(handle, "hwdec", "auto"))

    let api = UnsafeMutableRawPointer(
      mutating: (MPV_RENDER_API_TYPE_SW as NSString).utf8String
    )
    var params: [mpv_render_param] = [
      mpv_render_param(type: MPV_RENDER_PARAM_API_TYPE, data: api),
      mpv_render_param(type: MPV_RENDER_PARAM_INVALID, data: nil),
    ]

    MPVHelpers.checkError(
      mpv_render_context_create(&renderContext, handle, &params)
    )

    mpv_render_context_set_update_callback(
      renderContext,
      { (ctx) in
        let that = unsafeBitCast(ctx, to: TextureSW.self)
        DispatchQueue.main.async {
          that.updateCallback()
        }
      },
      UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
    )
  }

  private func disposeMPV() {
    mpv_render_context_free(renderContext)
  }

  public func resize(_ size: CGSize) {
    if size.width == 0 || size.height == 0 {
      return
    }

    NSLog("TextureSW: resize: \(size.width)x\(size.height)")
    createPixelBuffer(size)
  }

  private func createPixelBuffer(_ size: CGSize) {
    disposePixelBuffer()

    let attrs =
      [
        kCVPixelBufferMetalCompatibilityKey: true
      ] as CFDictionary

    var pixelBuffer: CVPixelBuffer?
    let cvret = CVPixelBufferCreate(
      kCFAllocatorDefault,
      Int(size.width),
      Int(size.height),
      kCVPixelFormatType_32BGRA,
      attrs,
      &pixelBuffer
    )
    assert(cvret == kCVReturnSuccess, "CVPixelBufferCreate")

    self.pixelBuffer = pixelBuffer
  }

  private func disposePixelBuffer() {
    // 'CVPixelBufferRelease' is unavailable: Core Foundation objects are
    // automatically memory managed
  }

  public func render(_ size: CGSize) {
    if pixelBuffer == nil {
      return
    }

    CVPixelBufferLockBaseAddress(
      pixelBuffer!,
      CVPixelBufferLockFlags(rawValue: 0)
    )
    defer {
      CVPixelBufferUnlockBaseAddress(
        pixelBuffer!,
        CVPixelBufferLockFlags(rawValue: 0)
      )
    }

    var ssize: [Int32] = [Int32(size.width), Int32(size.height)]
    let format: String = "bgr0"
    var pitch: Int = CVPixelBufferGetBytesPerRow(pixelBuffer!)
    let buffer = CVPixelBufferGetBaseAddress(pixelBuffer!)

    // pointers
    let ssizePtr = ssize.withUnsafeMutableBytes {
      $0.baseAddress?.assumingMemoryBound(to: Int32.self)
    }
    let formatPtr = UnsafeMutablePointer(
      mutating: (format as NSString).utf8String
    )
    let pitchPtr = withUnsafeMutablePointer(to: &pitch) { $0 }
    let bufferPtr = buffer!.assumingMemoryBound(to: UInt8.self)

    var params: [mpv_render_param] = [
      mpv_render_param(type: MPV_RENDER_PARAM_SW_SIZE, data: ssizePtr),
      mpv_render_param(type: MPV_RENDER_PARAM_SW_FORMAT, data: formatPtr),
      mpv_render_param(type: MPV_RENDER_PARAM_SW_STRIDE, data: pitchPtr),
      mpv_render_param(type: MPV_RENDER_PARAM_SW_POINTER, data: bufferPtr),
      mpv_render_param(type: MPV_RENDER_PARAM_INVALID, data: nil),
    ]

    mpv_render_context_render(renderContext, &params)
  }
}
