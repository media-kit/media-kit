// This file is a part of media_kit
// (https://github.com/media-kit/media-kit).
//
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.
//
// The isolated EGL context of the video outputs (isolated_egl.cc) next to the
// GL context GDK leaves current on the platform thread. Run on a display, or
// on a virtual one, from media_kit_video/linux:
//
//   g++ -std=c++17 -o isolated_egl_test test/isolated_egl_test.cc isolated_egl.cc
//     $(pkg-config --cflags --libs gtk+-3.0 epoxy)
//   GDK_BACKEND=x11 xvfb-run -a ./isolated_egl_test
//
// It paints a GTK window that holds GL content as Flutter's view does, so that
// GDK keeps its GL context current (GLX on X11), then checks that the isolated
// context is made current, that GDK's context and an EGL context of another
// thread kind (Flutter's on its raster thread) are current again after, and
// says whether textures reach another context through an EGLImage. Exit 0 when
// every check holds, 1 otherwise; 0 with a note when GDK has no GL here.

#include <gtk/gtk.h>

#include <epoxy/egl.h>
#include <epoxy/gl.h>

#include "../include/media_kit_video/isolated_egl.h"

static int failures = 0;

static void check(gboolean condition, const gchar* what) {
  g_print("  %s: %s\n", condition ? "ok" : "FAILED", what);
  if (!condition) {
    failures++;
  }
}

static gboolean painted = FALSE;

// What Flutter's view does on each frame (fl_view_renderer.cc): its own GDK
// context current while it draws, cleared after; GDK then composites with its
// paint context and leaves that one current.
static gboolean draw(GtkWidget* widget, cairo_t* cr, gpointer data) {
  GdkGLContext* context = GDK_GL_CONTEXT(data);
  gdk_gl_context_make_current(context);
  GLuint texture = 0;
  glGenTextures(1, &texture);
  glBindTexture(GL_TEXTURE_2D, texture);
  guint8 pixels[4 * 16 * 16];
  memset(pixels, 0x80, sizeof(pixels));
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 16, 16, 0, GL_RGBA, GL_UNSIGNED_BYTE,
               pixels);
  gdk_cairo_draw_from_gl(cr, gtk_widget_get_window(widget), texture,
                         GL_TEXTURE, 1, 0, 0, 16, 16);
  glDeleteTextures(1, &texture);
  gdk_gl_context_clear_current();
  painted = TRUE;
  return TRUE;
}

int main(int argc, char** argv) {
  if (!gtk_init_check(&argc, &argv)) {
    g_print("no display: run on one (xvfb-run)\n");
    return 1;
  }
  g_print("-- %s display\n", isolated_egl_windowing_system());

  GtkWidget* window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_default_size(GTK_WINDOW(window), 64, 64);
  GtkWidget* area = gtk_drawing_area_new();
  gtk_container_add(GTK_CONTAINER(window), area);
  gtk_widget_set_app_paintable(area, TRUE);
  gtk_widget_show_all(window);

  g_autoptr(GError) error = NULL;
  g_autoptr(GdkGLContext) view_context =
      gdk_window_create_gl_context(gtk_widget_get_window(area), &error);
  if (view_context == NULL ||
      !gdk_gl_context_realize(view_context, &error)) {
    g_print("GDK has no GL on this display (%s): Flutter renders in software "
            "and video outputs never try EGL here\n",
            error != NULL ? error->message : "no context");
    return 0;
  }
  g_signal_connect(area, "draw", G_CALLBACK(draw), view_context);
  gtk_widget_queue_draw(area);
  for (int i = 0; i < 200 && !painted; i++) {
    gtk_main_iteration_do(FALSE);
    g_usleep(10000);
  }
  // A last round, so that the paint is ended (gdk_window_end_paint_internal)
  while (gtk_events_pending()) {
    gtk_main_iteration_do(FALSE);
  }
  check(painted, "the window was painted with GL content");

  GdkGLContext* gdk_current = gdk_gl_context_get_current();
  g_print("-- after a paint, GDK's GL context %s current on this thread\n",
          gdk_current != NULL ? "is" : "is not");

  EGLDisplay display = isolated_egl_display_from_gdk();
  check(display != EGL_NO_DISPLAY, "an EGL display from GDK's display");
  if (display == EGL_NO_DISPLAY) {
    return 1;
  }
  g_print("  EGL %s, %s\n", eglQueryString(display, EGL_VERSION),
          eglQueryString(display, EGL_VENDOR));
  EGLConfig config = isolated_egl_choose_config(display);
  check(config != NULL, "an OpenGL ES 2.0 config");
  if (config == NULL) {
    return 1;
  }
  EGLContext context = isolated_egl_create_context(display, config);
  check(context != EGL_NO_CONTEXT, "an isolated context");
  if (context == EGL_NO_CONTEXT) {
    return 1;
  }

  if (gdk_current != NULL) {
    // What video_output.cc did before this change, for the record only:
    // libglvnd refuses it while GDK's GLX context is current, Mesa alone may
    // not
    if (eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, context)) {
      g_print("-- before the fix: eglMakeCurrent went through\n");
      eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
      gdk_gl_context_make_current(gdk_current);
    } else {
      g_print("-- before the fix: eglMakeCurrent failed, error 0x%x\n",
              eglGetError());
    }
  }

  g_print("-- on the platform thread, after GDK painted\n");
  IsolatedEglSaved saved;
  EGLint make_current_error = EGL_SUCCESS;
  gboolean entered =
      isolated_egl_enter(display, context, &saved, &make_current_error);
  if (!entered) {
    g_print("  EGL error 0x%x\n", make_current_error);
  }
  check(entered, "the isolated context is made current");
  check(!entered || eglGetCurrentContext() == context,
        "eglGetCurrentContext is the isolated context");
  if (entered) {
    g_print("  renderer: %s\n", (const char*)glGetString(GL_RENDERER));
    const gchar* problem = isolated_egl_texture_sharing_problem(display, context);
    g_print("  textures through an EGLImage: %s\n",
            problem == NULL ? "yes, the hardware path of the video outputs"
                            : problem);
  }
  isolated_egl_leave(display, &saved);
  check(eglGetCurrentContext() != context,
        "the isolated context is released after");
  check(gdk_gl_context_get_current() == gdk_current,
        "GDK's context is current again, as GDK believes");

  g_print("-- on a thread where another EGL context is current (Flutter's "
          "raster thread)\n");
  gdk_gl_context_clear_current();
  EGLContext other = isolated_egl_create_context(display, config);
  check(other != EGL_NO_CONTEXT &&
            eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, other),
        "another context current");
  entered = isolated_egl_enter(display, context, &saved, &make_current_error);
  check(entered, "the isolated context is made current");
  isolated_egl_leave(display, &saved);
  check(eglGetCurrentContext() == other, "the other context is current again");
  eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
  eglDestroyContext(display, other);
  eglDestroyContext(display, context);
  if (gdk_current != NULL) {
    gdk_gl_context_make_current(gdk_current);
  }

  gtk_widget_destroy(window);
  g_print(failures == 0 ? "-- every check holds\n" : "-- %d checks failed\n",
          failures);
  return failures == 0 ? 0 : 1;
}
