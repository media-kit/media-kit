// This file is a part of media_kit
// (https://github.com/media-kit/media-kit).
//
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.
//
// Why a video output fell back to S/W rendering on X11 while Wayland rendered
// with the GPU ("Failed to make isolated EGL context current. Error: 0x3002"):
// GTK 3 paints a window that holds GL content through a GL context of its own,
// GLX on X11 and EGL on Wayland, and leaves that context current on the
// platform thread once a frame is painted (gdk_window_end_paint_internal makes
// it current and never clears it). Flutter's view paints so on every frame.
// libglvnd, which dispatches EGL and GLX on the distributions, refuses an EGL
// context on a thread where a context of another window system API is current:
// eglMakeCurrent fails with EGL_BAD_ACCESS ("Another window API already has a
// current context", src/EGL/libegl.c). Under Wayland GDK's context is an EGL
// one, so the switch went through, though GDK then wrongly believed its context
// still current. The helpers below put GDK's context aside through GDK before
// the isolated context is made current, and make it current again after, on
// X11 and Wayland alike. Flutter itself renders on its raster thread with EGL
// contexts of the same display (fl_opengl_manager.cc), which GDK never touches.

#include "include/media_kit_video/isolated_egl.h"

#include <epoxy/gl.h>
#include <gdk/gdkwayland.h>
#include <gdk/gdkx.h>

// eglGetPlatformDisplayEXT is looked up through eglGetProcAddress because
// epoxy's own dispatch of eglGetPlatformDisplay asks for EGL 1.5 on the
// current display, which does not exist yet here (reported in #1404).
typedef EGLDisplay (*IsolatedEglGetPlatformDisplay)(EGLenum platform,
                                                    void* native_display,
                                                    const EGLint* attrib_list);

EGLDisplay isolated_egl_display_from_gdk() {
  auto get_platform_display = (IsolatedEglGetPlatformDisplay)eglGetProcAddress(
      "eglGetPlatformDisplayEXT");
  if (get_platform_display == NULL) {
    g_printerr("media_kit: VideoOutput: eglGetPlatformDisplayEXT is missing.\n");
    return EGL_NO_DISPLAY;
  }
  GdkDisplay* gdk_display = gdk_display_get_default();
  EGLDisplay egl_display = EGL_NO_DISPLAY;
  if (GDK_IS_WAYLAND_DISPLAY(gdk_display)) {
    egl_display = get_platform_display(
        EGL_PLATFORM_WAYLAND_KHR,
        gdk_wayland_display_get_wl_display(gdk_display), NULL);
  } else if (GDK_IS_X11_DISPLAY(gdk_display)) {
    egl_display = get_platform_display(
        EGL_PLATFORM_X11_KHR, gdk_x11_display_get_xdisplay(gdk_display), NULL);
  }
  // eglGetPlatformDisplay returns the same handle for the same platform and
  // native display (EGL 1.5, 3.2): the display Flutter renders on. A second
  // eglInitialize changes nothing; the display is never terminated here.
  if (egl_display == EGL_NO_DISPLAY ||
      !eglInitialize(egl_display, NULL, NULL)) {
    g_printerr("media_kit: VideoOutput: No EGL display from GDK. Error: 0x%x\n",
               eglGetError());
    return EGL_NO_DISPLAY;
  }
  return egl_display;
}

const gchar* isolated_egl_windowing_system() {
  GdkDisplay* gdk_display = gdk_display_get_default();
  if (GDK_IS_WAYLAND_DISPLAY(gdk_display)) {
    return "Wayland";
  }
  if (GDK_IS_X11_DISPLAY(gdk_display)) {
    return "X11";
  }
  return "another backend";
}

EGLConfig isolated_egl_choose_config(EGLDisplay display) {
  EGLint attributes[] = {
      EGL_RED_SIZE,        8,
      EGL_GREEN_SIZE,      8,
      EGL_BLUE_SIZE,       8,
      EGL_ALPHA_SIZE,      8,
      EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
      EGL_NONE,
  };
  EGLConfig config = NULL;
  EGLint count = 0;
  if (!eglChooseConfig(display, attributes, &config, 1, &count) ||
      count == 0) {
    g_printerr("media_kit: VideoOutput: No EGL config. Error: 0x%x\n",
               eglGetError());
    return NULL;
  }
  return config;
}

EGLContext isolated_egl_create_context(EGLDisplay display, EGLConfig config) {
  // The bound API decides the kind of context eglCreateContext makes; the one
  // the thread had is bound again after.
  EGLenum api = eglQueryAPI();
  eglBindAPI(EGL_OPENGL_ES_API);
  EGLint attributes[] = {
      EGL_CONTEXT_CLIENT_VERSION, 2,
      EGL_NONE,
  };
  EGLContext context =
      eglCreateContext(display, config, EGL_NO_CONTEXT, attributes);
  if (context == EGL_NO_CONTEXT) {
    g_printerr(
        "media_kit: VideoOutput: Failed to create isolated EGL context. "
        "Error: 0x%x\n",
        eglGetError());
  }
  if (api != EGL_NONE) {
    eglBindAPI(api);
  }
  return context;
}

gboolean isolated_egl_enter(EGLDisplay display,
                            EGLContext context,
                            IsolatedEglSaved* saved,
                            EGLint* error) {
  saved->gdk_context = gdk_gl_context_get_current();
  if (saved->gdk_context != NULL) {
    g_object_ref(saved->gdk_context);
  }
  saved->display = eglGetCurrentDisplay();
  saved->context = eglGetCurrentContext();
  saved->draw = eglGetCurrentSurface(EGL_DRAW);
  saved->read = eglGetCurrentSurface(EGL_READ);
  saved->api = eglQueryAPI();
  if (saved->gdk_context != NULL) {
    // glXMakeContextCurrent(None) on X11, eglMakeCurrent(EGL_NO_CONTEXT) on
    // Wayland: the thread is free for an EGL context
    gdk_gl_context_clear_current();
  }
  eglBindAPI(EGL_OPENGL_ES_API);
  if (eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, context)) {
    *error = EGL_SUCCESS;
    return TRUE;
  }
  *error = eglGetError();
  return FALSE;
}

void isolated_egl_leave(EGLDisplay display, IsolatedEglSaved* saved) {
  if (saved->gdk_context == NULL && saved->context != EGL_NO_CONTEXT) {
    // An EGL context that is not GDK's, such as Flutter's on its raster thread
    eglMakeCurrent(saved->display, saved->draw, saved->read, saved->context);
  } else {
    // Released on |display|: eglMakeCurrent with EGL_NO_DISPLAY releases
    // nothing where EGL is Mesa's without libglvnd
    eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
  }
  if (saved->api != EGL_NONE) {
    eglBindAPI(saved->api);
  }
  if (saved->gdk_context != NULL) {
    // GDK's context comes back through GDK, which knows its surfaces (on
    // Wayland the EGL context saved above is that one)
    gdk_gl_context_make_current(saved->gdk_context);
    g_clear_object(&saved->gdk_context);
  }
}

const gchar* isolated_egl_texture_sharing_problem(EGLDisplay display,
                                                  EGLContext context) {
  if (!epoxy_has_egl_extension(display, "EGL_KHR_image_base") ||
      !epoxy_has_egl_extension(display, "EGL_KHR_gl_texture_2D_image")) {
    return "the EGL display cannot make an EGLImage of a texture";
  }
  if (!epoxy_has_gl_extension("GL_OES_EGL_image")) {
    return "the OpenGL ES context cannot read an EGLImage "
           "(no GL_OES_EGL_image)";
  }
  // The functions TextureGL calls (texture_gl.cc), as it finds them
  if (eglGetProcAddress("eglCreateImageKHR") == NULL ||
      eglGetProcAddress("eglDestroyImageKHR") == NULL ||
      eglGetProcAddress("glEGLImageTargetTexture2DOES") == NULL) {
    return "the EGLImage functions are missing";
  }
  // A 1x1 texture made an EGLImage, then read into another texture, as
  // TextureGL hands each frame from mpv's context to Flutter's
  // Errors left by earlier calls, a few at most (a lost context repeats one)
  for (int i = 0; i < 8 && glGetError() != GL_NO_ERROR; i++) {
  }
  GLuint textures[2] = {0, 0};
  glGenTextures(2, textures);
  glBindTexture(GL_TEXTURE_2D, textures[0]);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE,
               NULL);
  EGLint attributes[] = {EGL_NONE};
  EGLImageKHR image = eglCreateImageKHR(display, context, EGL_GL_TEXTURE_2D_KHR,
                                        (EGLClientBuffer)(guintptr)textures[0],
                                        attributes);
  const gchar* problem = NULL;
  if (image == EGL_NO_IMAGE_KHR) {
    problem = "the EGL display refused an EGLImage of a texture";
  } else {
    glBindTexture(GL_TEXTURE_2D, textures[1]);
    glEGLImageTargetTexture2DOES(GL_TEXTURE_2D, (GLeglImageOES)image);
    if (glGetError() != GL_NO_ERROR) {
      problem = "the OpenGL ES context refused the EGLImage of a texture";
    }
    eglDestroyImageKHR(display, image);
  }
  glBindTexture(GL_TEXTURE_2D, 0);
  glDeleteTextures(2, textures);
  return problem;
}
