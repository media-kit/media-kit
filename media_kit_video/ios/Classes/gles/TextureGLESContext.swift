public class TextureGLESContext {
  private let context: EAGLContext
  private let renderBuffer: GLuint
  public let frameBuffer: GLuint
  public let texture: CVOpenGLESTexture
  public let pixelBuffer: CVPixelBuffer

  init(
    context: EAGLContext,
    textureCache: CVOpenGLESTextureCache,
    size: CGSize
  ) {
    self.context = context

    self.pixelBuffer = OpenGLESHelpers.createPixelBuffer(size)

    self.texture = OpenGLESHelpers.createTexture(
      textureCache,
      pixelBuffer,
      size
    )

    self.renderBuffer = OpenGLESHelpers.createRenderBuffer(
      context,
      size
    )

    self.frameBuffer = OpenGLESHelpers.createFrameBuffer(
      context: context,
      renderBuffer: renderBuffer,
      texture: texture,
      size: size
    )
  }

  deinit {
    OpenGLESHelpers.deletePixeBuffer(context, pixelBuffer)
    OpenGLESHelpers.deleteTexture(context, texture)
    OpenGLESHelpers.deleteRenderBuffer(context, renderBuffer)
    OpenGLESHelpers.deleteFrameBuffer(context, frameBuffer)
  }
}
