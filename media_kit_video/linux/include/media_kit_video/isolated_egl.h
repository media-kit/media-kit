// This file is a part of media_kit
// (https://github.com/media-kit/media-kit).
//
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.
//
// The isolated EGL context of a video output, made current on a thread
// whatever GDK left current there. Free of Flutter, so that
// linux/test/isolated_egl_test.cc checks it on its own.

#ifndef ISOLATED_EGL_H_
#define ISOLATED_EGL_H_

#include <epoxy/egl.h>
#include <gdk/gdk.h>

// What a thread had current before isolated_egl_enter: GDK's GL context (GLX
// on X11, EGL on Wayland), the EGL context with its display and surfaces, and
// the EGL client API bound on the thread.
typedef struct _IsolatedEglSaved {
  GdkGLContext* gdk_context;
  EGLDisplay display;
  EGLContext context;
  EGLSurface draw;
  EGLSurface read;
  EGLenum api;
} IsolatedEglSaved;

// The EGLDisplay of GDK's native display (X11 or Wayland), the one Flutter
// renders on; EGL_NO_DISPLAY, said in the log, when there is none.
EGLDisplay isolated_egl_display_from_gdk();

// "X11", "Wayland" or "another backend", for the log.
const gchar* isolated_egl_windowing_system();

// An RGBA 8 bit config of |display| that renders OpenGL ES 2.0, as Flutter
// picks its own; NULL, said in the log, when there is none.
EGLConfig isolated_egl_choose_config(EGLDisplay display);

// An OpenGL ES 2.0 context of |display| that shares nothing with another
// context; EGL_NO_CONTEXT, said in the log, when it cannot be made.
EGLContext isolated_egl_create_context(EGLDisplay display, EGLConfig config);

// Puts aside what the calling thread has current (GDK's GL context through GDK,
// so that GDK knows it is no longer current, and the current EGL context), then
// makes |context| current without a surface. Returns FALSE with the EGL error
// in |error| when |context| could not be made current; the thread then has no
// context current. In both cases isolated_egl_leave must follow.
gboolean isolated_egl_enter(EGLDisplay display,
                            EGLContext context,
                            IsolatedEglSaved* saved,
                            EGLint* error);

// Releases |display|'s context from the calling thread and makes current again
// what isolated_egl_enter put aside.
void isolated_egl_leave(EGLDisplay display, IsolatedEglSaved* saved);

// Whether a texture of the current context reaches another context through an
// EGLImage, as TextureGL hands mpv's frames to Flutter: the extensions of
// |display| and of the context, the functions, and a 1x1 texture shared for
// real. NULL when it does, else the reason, for the log. Call it with the
// isolated context current.
const gchar* isolated_egl_texture_sharing_problem(EGLDisplay display,
                                                  EGLContext context);

#endif  // ISOLATED_EGL_H_
