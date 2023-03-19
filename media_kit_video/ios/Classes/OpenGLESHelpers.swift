import OpenGLES
import UIKit

public class OpenGLESHelpers {
  static public func createContext() -> EAGLContext {
    let context = EAGLContext(api: .openGLES3)
    return context!
  }

  static public func createTextureCache(
    _ context: EAGLContext
  ) -> CVOpenGLESTextureCache {
    var textureCache: CVOpenGLESTextureCache?

    let cvret: CVReturn = CVOpenGLESTextureCacheCreate(
      kCFAllocatorDefault,
      nil,
      context,
      nil,
      &textureCache
    )
    assert(cvret == kCVReturnSuccess, "CVOpenGLESTextureCacheCreate")

    return textureCache!
  }

  static public func createPixelBuffer(_ size: CGSize) -> CVPixelBuffer {
    var pixelBuffer: CVPixelBuffer?

    let attrs =
      [
        kCVPixelBufferMetalCompatibilityKey: true
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
    _ textureCache: CVOpenGLESTextureCache,
    _ pixelBuffer: CVPixelBuffer,
    _ size: CGSize
  ) -> CVOpenGLESTexture {
    var texture: CVOpenGLESTexture?

    let cvret: CVReturn = CVOpenGLESTextureCacheCreateTextureFromImage(
      kCFAllocatorDefault,
      textureCache,
      pixelBuffer,
      nil,
      GLenum(GL_TEXTURE_2D),
      GL_RGBA,
      GLsizei(size.width),
      GLsizei(size.height),
      GLenum(GL_BGRA),
      GLenum(GL_UNSIGNED_BYTE),
      0,
      &texture
    )
    assert(
      cvret == kCVReturnSuccess,
      "CVOpenGLESTextureCacheCreateTextureFromImage"
    )

    return texture!
  }

  static public func createRenderBuffer(
    _ context: EAGLContext,
    _ size: CGSize
  ) -> GLuint {
    EAGLContext.setCurrent(context)
    defer {
      OpenGLESHelpers.checkError("createRenderBuffer")
      EAGLContext.setCurrent(nil)
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
    context: EAGLContext,
    renderBuffer: GLuint,
    texture: CVOpenGLESTexture,
    size: CGSize
  ) -> GLuint {
    EAGLContext.setCurrent(context)
    defer {
      OpenGLESHelpers.checkError("createFrameBuffer")
      EAGLContext.setCurrent(nil)
    }

    let textureName: GLuint = CVOpenGLESTextureGetName(texture)
    glBindTexture(GLenum(GL_TEXTURE_2D), textureName)
    defer {
      glBindTexture(GLenum(GL_TEXTURE_2D), 0)
    }

    glTexParameteri(
      GLenum(GL_TEXTURE_2D),
      GLenum(GL_TEXTURE_MAG_FILTER),
      GL_LINEAR
    )
    glTexParameteri(
      GLenum(GL_TEXTURE_2D),
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
      GLenum(GL_TEXTURE_2D),
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

  static public func deleteContext(_ context: EAGLContext) {
    // Release function for EAGLContext not found
  }

  static public func deleteTextureCache(_ textureCache: CVOpenGLESTextureCache) {
    CVOpenGLESTextureCacheFlush(textureCache, 0)

    // 'CVOpenGLESTextureCacheRelease' is unavailable: Core Foundation objects are
    // automatically memory managed
  }

  static public func deletePixeBuffer(
    _ context: EAGLContext,
    _ pixelBuffer: CVPixelBuffer
  ) {
    // 'CVPixelBufferRelease' is unavailable: Core Foundation objects are
    // automatically memory managed
  }

  static public func deleteTexture(
    _ context: EAGLContext,
    _ texture: CVOpenGLESTexture
  ) {
    EAGLContext.setCurrent(context)
    defer {
      OpenGLESHelpers.checkError("deleteTexture")
      EAGLContext.setCurrent(nil)
    }

    var textureName: GLuint = CVOpenGLESTextureGetName(texture)
    glDeleteTextures(1, &textureName)
  }

  static public func deleteRenderBuffer(
    _ context: EAGLContext,
    _ renderBuffer: GLuint
  ) {
    EAGLContext.setCurrent(context)
    defer {
      OpenGLESHelpers.checkError("deleteRenderBuffer")
      EAGLContext.setCurrent(nil)
    }

    var renderBuffer = renderBuffer
    glDeleteRenderbuffers(1, &renderBuffer)
  }

  static public func deleteFrameBuffer(
    _ context: EAGLContext,
    _ frameBuffer: GLuint
  ) {
    EAGLContext.setCurrent(context)
    defer {
      OpenGLESHelpers.checkError("deleteFrameBuffer")
      EAGLContext.setCurrent(nil)
    }

    var frameBuffer = frameBuffer
    glDeleteFramebuffers(1, &frameBuffer)
  }

  static public func checkError(_ message: String) {
    let error = glGetError()
    if error == GL_NO_ERROR {
      return
    }

    NSLog("OpenGLESHelpers: error: \(message): \(error)")
  }
}
