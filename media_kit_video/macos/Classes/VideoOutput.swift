import Cocoa
import FlutterMacOS
import GLKit

public class VideoOutput: NSObject, FlutterTexture {
  public typealias TextureUpdateCallback = (Int64, CGSize) -> Void

  private let handle: OpaquePointer
  private let width: Int64?
  private let height: Int64?
  private let registry: FlutterTextureRegistry
  private let textureUpdateCallback: TextureUpdateCallback
  private let context: NSOpenGLContext
  private let textureCache: CVOpenGLTextureCache
  private var textureId: Int64 = -1
  private var renderContext: OpaquePointer?
  private var currentWidth: Int64 = 0
  private var currentHeight: Int64 = 0
  private var pixelBuffer: CVPixelBuffer?
  private var texture: CVOpenGLTexture?
  private var frameBuffer: GLuint?
  private var renderBuffer: GLuint?
  private var disposed: Bool = false

  init(
    handle: Int64,
    width: Int64?,
    height: Int64?,
    registry: FlutterTextureRegistry,
    textureUpdateCallback: @escaping TextureUpdateCallback
  ) {
    let handle = OpaquePointer(bitPattern: Int(handle))
    assert(handle != nil, "handle casting")

    self.handle = handle!
    self.width = width
    self.height = height
    self.registry = registry
    self.textureUpdateCallback = textureUpdateCallback
    self.context = OpenGLHelpers.createContext()
    self.textureCache = OpenGLHelpers.createTextureCache(context)

    super.init()

    self.textureId = self.registry.register(self)
    textureUpdateCallback(textureId, CGSize(width: 0, height: 0))

    DispatchQueue.main.async {
      self.initMPV()
    }
  }

  public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
    if pixelBuffer == nil {
      return nil
    }

    let result = Unmanaged.passRetained(pixelBuffer!)
    return result
  }

  public func dispose() {
    disposed = true

    disposeTextureId()
    disposePixelBuffer()
    disposeMPV()
    OpenGLHelpers.deleteTextureCache(textureCache)
    OpenGLHelpers.deleteContext(context)
  }

  private func disposeTextureId() {
    registry.unregisterTexture(textureId)
    self.textureId = -1
  }

  private func initMPV() {
    context.makeCurrentContext()
    defer {
      OpenGLHelpers.checkGLError("initMPV")
      NSOpenGLContext.clearCurrentContext()
    }

    checkMPVError(mpv_set_option_string(handle, "hwdec", "auto"))

    let api = UnsafeMutableRawPointer(
      mutating: (MPV_RENDER_API_TYPE_OPENGL as NSString).utf8String
    )
    var procAddress = mpv_opengl_init_params(
      get_proc_address: {
        (ctx, name) in
        return VideoOutput.getProcAddress(ctx, name)
      },
      get_proc_address_ctx: nil
    )

    var params: [mpv_render_param] = withUnsafeMutableBytes(of: &procAddress) {
      procAddress in
      return [
        mpv_render_param(type: MPV_RENDER_PARAM_API_TYPE, data: api),
        mpv_render_param(
          type: MPV_RENDER_PARAM_OPENGL_INIT_PARAMS,
          data: procAddress.baseAddress.map {
            UnsafeMutableRawPointer($0)
          }
        ),
        mpv_render_param(),
      ]
    }

    checkMPVError(mpv_render_context_create(&renderContext, handle, &params))

    mpv_render_context_set_update_callback(
      renderContext,
      { (ctx) in
        let that = unsafeBitCast(ctx, to: VideoOutput.self)
        DispatchQueue.main.async {
          if that.disposed {
            return
          }

          that.updateCallback()
        }
      },
      UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
    )
  }

  private func disposeMPV() {
    mpv_render_context_free(renderContext)
    self.renderContext = nil
  }

  private func updateCallback() {
    defer {
      registry.textureFrameAvailable(self.textureId)
    }

    let width = self.videoWidth
    let height = self.videoHeight

    let size = CGSize(
      width: Double(width),
      height: Double(height)
    )

    if self.currentWidth != width || self.currentHeight != height {
      self.currentWidth = width
      self.currentHeight = height

      if width == 0 || height == 0 {
        disposePixelBuffer()
      } else {
        createPixelBuffer(size)
      }

      textureUpdateCallback(textureId, size)
    }

    if width == 0 || height == 0 {
      return
    }

    render(size)
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

  private func disposePixelBuffer() {
    if pixelBuffer == nil {
      return
    }

    OpenGLHelpers.deletePixeBuffer(context, self.pixelBuffer!)
    OpenGLHelpers.deleteTexture(context, self.texture!)
    OpenGLHelpers.deleteRenderBuffer(context, self.renderBuffer!)
    OpenGLHelpers.deleteFrameBuffer(context, self.frameBuffer!)

    self.pixelBuffer = nil
    self.texture = nil
    self.renderBuffer = nil
    self.frameBuffer = nil
  }

  private func createPixelBuffer(_ size: CGSize) {
    disposePixelBuffer()

    NSLog("createPixelBuffer: \(size.width)x\(size.height)")

    self.pixelBuffer = OpenGLHelpers.createPixelBuffer(size)

    self.texture = OpenGLHelpers.createTexture(
      textureCache,
      pixelBuffer!
    )

    self.renderBuffer = OpenGLHelpers.createRenderBuffer(
      context,
      size
    )

    self.frameBuffer = OpenGLHelpers.createFrameBuffer(
      context: context,
      renderBuffer: renderBuffer!,
      texture: texture!,
      size: size
    )
  }

  private func render(_ size: CGSize) {
    if frameBuffer == nil {
      return
    }

    context.makeCurrentContext()
    defer {
      OpenGLHelpers.checkGLError("render")
      NSOpenGLContext.clearCurrentContext()
    }

    glBindFramebuffer(GLenum(GL_FRAMEBUFFER), frameBuffer!)
    defer {
      glBindFramebuffer(GLenum(GL_FRAMEBUFFER), 0)
    }

    var fbo = mpv_opengl_fbo(
      fbo: Int32(self.frameBuffer!),
      w: Int32(size.width),
      h: Int32(size.height),
      internal_format: 0
    )
    var params: [mpv_render_param] =
      withUnsafeMutableBytes(of: &fbo) {
        fbo in
        return [
          mpv_render_param(
            type: MPV_RENDER_PARAM_OPENGL_FBO,
            data: fbo.baseAddress.map {
              UnsafeMutableRawPointer($0)
            }
          ),
          mpv_render_param(
            type: MPV_RENDER_PARAM_INVALID,
            data: nil
          ),
        ]
      }
    mpv_render_context_render(renderContext, &params)

    glFlush()
  }

  private func checkMPVError(_ status: CInt) {
    if status < 0 {
      NSLog("mpv API error: \(mpv_error_string(status) as Any)")
      exit(1)
    }
  }

  static private func getProcAddress(
    _ ctx: UnsafeMutableRawPointer?,
    _ name: UnsafePointer<Int8>?
  ) -> UnsafeMutableRawPointer? {
    let symbol: CFString = CFStringCreateWithCString(
      kCFAllocatorDefault,
      name,
      kCFStringEncodingASCII
    )
    let indentifier = CFBundleGetBundleWithIdentifier(
      "com.apple.opengl" as CFString
    )
    let addr = CFBundleGetFunctionPointerForName(indentifier, symbol)

    if addr == nil {
      NSLog("Cannot get OpenGL function pointer!")
    }
    return addr
  }
}
