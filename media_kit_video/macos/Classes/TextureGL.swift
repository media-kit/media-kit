import Cocoa
import FlutterMacOS
import OpenGL.GL
import OpenGL.GL3

public class TextureGL: NSObject, FlutterTexture, ResizableTextureProtocol {
  public typealias UpdateCallback = () -> Void

  private let handle: OpaquePointer
  private let updateCallback: UpdateCallback
  private let pixelFormat: CGLPixelFormatObj
  private let context: CGLContextObj
  private let textureCache: CVOpenGLTextureCache
  private var renderContext: OpaquePointer?
  private var pixelBuffer: CVPixelBuffer?
  private var texture: CVOpenGLTexture?
  private var frameBuffer: GLuint?
  private var renderBuffer: GLuint?

  init(
    handle: OpaquePointer,
    updateCallback: @escaping UpdateCallback
  ) {
    self.handle = handle
    self.updateCallback = updateCallback
    self.pixelFormat = OpenGLHelpers.createPixelFormat()
    self.context = OpenGLHelpers.createContext(pixelFormat)
    self.textureCache = OpenGLHelpers.createTextureCache(context, pixelFormat)

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
    OpenGLHelpers.deleteTextureCache(textureCache)
    OpenGLHelpers.deletePixelFormat(pixelFormat)
    OpenGLHelpers.deleteContext(context)
  }

  private func initMPV() {
    CGLSetCurrentContext(context)
    defer {
      OpenGLHelpers.checkError("initMPV")
      CGLSetCurrentContext(nil)
    }

    MPVHelpers.checkError(mpv_set_option_string(handle, "hwdec", "auto"))

    let api = UnsafeMutableRawPointer(
      mutating: (MPV_RENDER_API_TYPE_OPENGL as NSString).utf8String
    )
    var procAddress = mpv_opengl_init_params(
      get_proc_address: {
        (ctx, name) in
        return TextureGL.getProcAddress(ctx, name)
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

    MPVHelpers.checkError(
      mpv_render_context_create(&renderContext, handle, &params)
    )

    mpv_render_context_set_update_callback(
      renderContext,
      { (ctx) in
        let that = unsafeBitCast(ctx, to: TextureGL.self)
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

    NSLog("TextureGL: resize: \(size.width)x\(size.height)")
    createPixelBuffer(size)
  }

  private func createPixelBuffer(_ size: CGSize) {
    disposePixelBuffer()

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

  private func disposePixelBuffer() {
    if pixelBuffer == nil {
      return
    }

    OpenGLHelpers.deletePixeBuffer(context, self.pixelBuffer!)
    OpenGLHelpers.deleteTexture(context, self.texture!)
    OpenGLHelpers.deleteRenderBuffer(context, self.renderBuffer!)
    OpenGLHelpers.deleteFrameBuffer(context, self.frameBuffer!)
  }

  public func render(_ size: CGSize) {
    if frameBuffer == nil {
      return
    }

    CGLSetCurrentContext(context)
    defer {
      OpenGLHelpers.checkError("render")
      CGLSetCurrentContext(nil)
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
    let fboPtr = withUnsafeMutablePointer(to: &fbo) { $0 }

    var params: [mpv_render_param] = [
      mpv_render_param(type: MPV_RENDER_PARAM_OPENGL_FBO, data: fboPtr),
      mpv_render_param(type: MPV_RENDER_PARAM_INVALID, data: nil),
    ]
    mpv_render_context_render(renderContext, &params)

    glFlush()
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
