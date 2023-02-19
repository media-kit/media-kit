import GLKit

public class OpenGLHelpers {
  static public func createContext() -> NSOpenGLContext {
    let attributes = [
      NSOpenGLPixelFormatAttribute(NSOpenGLPFAAllowOfflineRenderers),
      NSOpenGLPixelFormatAttribute(NSOpenGLPFAAccelerated),
      NSOpenGLPixelFormatAttribute(NSOpenGLPFADoubleBuffer),
      NSOpenGLPixelFormatAttribute(NSOpenGLPFAMultisample),
      NSOpenGLPixelFormatAttribute(NSOpenGLPFASampleBuffers), 1,
      NSOpenGLPixelFormatAttribute(NSOpenGLPFASamples), 4,
      NSOpenGLPixelFormatAttribute(NSOpenGLPFAMinimumPolicy),
      NSOpenGLPixelFormatAttribute(NSOpenGLPFAOpenGLProfile),
      NSOpenGLPixelFormatAttribute(NSOpenGLProfileVersion4_1Core),
      0,
    ]

    let pixelFormat = NSOpenGLPixelFormat(attributes: attributes)
    assert(pixelFormat != nil, "NSOpenGLPixelFormat")

    let context = NSOpenGLContext(format: pixelFormat!, share: nil)

    return context!
  }

  static public func createTextureCache(
    _ context: NSOpenGLContext
  ) -> CVOpenGLTextureCache {
    var textureCache: CVOpenGLTextureCache?

    let cvret: CVReturn = CVOpenGLTextureCacheCreate(
      kCFAllocatorDefault,
      nil,
      context.cglContextObj!,
      context.pixelFormat.cglPixelFormatObj!,
      nil,
      &textureCache
    )
    assert(cvret == kCVReturnSuccess, "CVOpenGLTextureCacheCreate")

    return textureCache!
  }

  static public func createPixelBuffer(_ size: CGSize) -> CVPixelBuffer {
    var pixelBuffer: CVPixelBuffer?

    let attrs =
      [
        kCVPixelBufferOpenGLCompatibilityKey: true,
        kCVPixelBufferMetalCompatibilityKey: true,
      ] as CFDictionary

    let cvret: CVReturn = CVPixelBufferCreate(
      kCFAllocatorDefault,
      Int(size.width),
      Int(size.height),
      kCVPixelFormatType_32BGRA,
      attrs,
      &pixelBuffer
    )
    assert(cvret == kCVReturnSuccess, "CVPixelBufferCreate")

    return pixelBuffer!
  }

  static public func createTexture(
    _ textureCache: CVOpenGLTextureCache,
    _ pixelBuffer: CVPixelBuffer
  ) -> CVOpenGLTexture {
    var texture: CVOpenGLTexture?

    let cvret: CVReturn = CVOpenGLTextureCacheCreateTextureFromImage(
      kCFAllocatorDefault,
      textureCache,
      pixelBuffer,
      nil,
      &texture
    )
    assert(
      cvret == kCVReturnSuccess,
      "CVOpenGLTextureCacheCreateTextureFromImage"
    )

    return texture!
  }

  static public func createRenderBuffer(
    _ context: NSOpenGLContext,
    _ size: CGSize
  ) -> GLuint {
    context.makeCurrentContext()
    defer {
      OpenGLHelpers.checkGLError("createRenderBuffer")
      NSOpenGLContext.clearCurrentContext()
    }

    var renderBuffer: GLuint = GLuint()
    glGenRenderbuffers(1, &renderBuffer)
    glBindRenderbuffer(GLenum(GL_RENDERBUFFER), renderBuffer)
    defer {
      glBindRenderbuffer(GLenum(GL_RENDERBUFFER), 0)
    }

    glRenderbufferStorage(
      GLenum(GL_RENDERBUFFER),
      GLenum(GL_DEPTH24_STENCIL8),
      GLsizei(size.width),
      GLsizei(size.height)
    )

    return renderBuffer
  }

  static public func createFrameBuffer(
    context: NSOpenGLContext,
    renderBuffer: GLuint,
    texture: CVOpenGLTexture,
    size: CGSize
  ) -> GLuint {
    context.makeCurrentContext()
    defer {
      OpenGLHelpers.checkGLError("createFrameBuffer")
      NSOpenGLContext.clearCurrentContext()
    }

    let textureName: GLuint = CVOpenGLTextureGetName(texture)
    glBindTexture(GLenum(GL_TEXTURE_RECTANGLE), textureName)
    defer {
      glBindTexture(GLenum(GL_TEXTURE_RECTANGLE), 0)
    }

    glTexParameteri(
      GLenum(GL_TEXTURE_RECTANGLE),
      GLenum(GL_TEXTURE_MAG_FILTER),
      GL_LINEAR
    )
    glTexParameteri(
      GLenum(GL_TEXTURE_RECTANGLE),
      GLenum(GL_TEXTURE_MIN_FILTER),
      GL_LINEAR
    )

    glViewport(0, 0, GLsizei(size.width), GLsizei(size.height))

    var frameBuffer: GLuint = 0
    glGenFramebuffers(1, &frameBuffer)
    glBindFramebuffer(GLenum(GL_FRAMEBUFFER), frameBuffer)
    defer {
      glBindFramebuffer(GLenum(GL_FRAMEBUFFER), 0)
    }

    glFramebufferTexture2D(
      GLenum(GL_FRAMEBUFFER),
      GLenum(GL_COLOR_ATTACHMENT0),
      GLenum(GL_TEXTURE_RECTANGLE),
      textureName,
      0
    )

    glFramebufferRenderbuffer(
      GLenum(GL_FRAMEBUFFER),
      GLenum(GL_DEPTH_ATTACHMENT),
      GLenum(GL_RENDERBUFFER),
      renderBuffer
    )

    return frameBuffer
  }

  static public func deleteContext(_ context: NSOpenGLContext) {
    NSOpenGLContext.clearCurrentContext()
    context.clearDrawable()
  }

  static public func deleteTextureCache(_ textureCache: CVOpenGLTextureCache) {
    CVOpenGLTextureCacheFlush(textureCache, 0)

    // 'CVOpenGLTextureCacheRelease' is unavailable: Core Foundation objects are
    // automatically memory managed
  }

  static public func deletePixeBuffer(
    _ context: NSOpenGLContext,
    _ pixelBuffer: CVPixelBuffer
  ) {
    // 'CVPixelBufferRelease' is unavailable: Core Foundation objects are
    // automatically memory managed
  }

  static public func deleteTexture(
    _ context: NSOpenGLContext,
    _ texture: CVOpenGLTexture
  ) {
    context.makeCurrentContext()
    defer {
      OpenGLHelpers.checkGLError("deleteTexture")
      NSOpenGLContext.clearCurrentContext()
    }

    var textureName: GLuint = CVOpenGLTextureGetName(texture)
    glDeleteTextures(1, &textureName)
  }

  static public func deleteRenderBuffer(
    _ context: NSOpenGLContext,
    _ renderBuffer: GLuint
  ) {
    context.makeCurrentContext()
    defer {
      OpenGLHelpers.checkGLError("deleteRenderBuffer")
      NSOpenGLContext.clearCurrentContext()
    }

    var renderBuffer = renderBuffer
    glDeleteRenderbuffers(1, &renderBuffer)
  }

  static public func deleteFrameBuffer(
    _ context: NSOpenGLContext,
    _ frameBuffer: GLuint
  ) {
    context.makeCurrentContext()
    defer {
      OpenGLHelpers.checkGLError("deleteFrameBuffer")
      NSOpenGLContext.clearCurrentContext()
    }

    var frameBuffer = frameBuffer
    glDeleteFramebuffers(1, &frameBuffer)
  }

  static public func clearScene(
    _ context: NSOpenGLContext,
    _ frameBuffer: GLuint,
    _ color: NSColor
  ) {
    context.makeCurrentContext()
    defer {
      OpenGLHelpers.checkGLError("clearScene")
      NSOpenGLContext.clearCurrentContext()
    }

    glBindFramebuffer(GLenum(GL_FRAMEBUFFER), frameBuffer)
    defer {
      glBindFramebuffer(GLenum(GL_FRAMEBUFFER), 0)
    }

    glClearColor(
      GLclampf(color.redComponent),
      GLclampf(color.greenComponent),
      GLclampf(color.blueComponent),
      GLclampf(color.alphaComponent)
    )
    glClear(GLbitfield(GL_COLOR_BUFFER_BIT))

    glFlush()
  }

  static public func checkGLError(_ message: String) {
    let error = glGetError()
    if error == GL_NO_ERROR {
      return
    }

    NSLog("GL_ERROR: \(message): \(error)")
  }
}
