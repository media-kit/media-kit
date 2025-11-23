// This file is a part of media_kit
// (https://github.com/media-kit/media-kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

#include "include/media_kit_video/video_output_manager.h"

// Linux-specific architecture: Per-player rendering threads
// Unlike Windows (which uses a single shared thread due to D3D11 constraints),
// Linux leverages EGL's multi-context support by giving each player its own
// dedicated rendering thread, enabling true parallel rendering.

struct _VideoOutputManager {
  GObject parent_instance;
  GHashTable* video_outputs;
  GHashTable* render_threads;  // Map: handle -> ThreadPool (each player has dedicated thread)
  FlTextureRegistrar* texture_registrar;
  FlView* view;
};

G_DEFINE_TYPE(VideoOutputManager, video_output_manager, G_TYPE_OBJECT)

static void video_output_manager_init(VideoOutputManager* self) {
  self->video_outputs = g_hash_table_new_full(g_direct_hash, g_direct_equal,
                                              nullptr, g_object_unref);
  // Each video output will have its own dedicated rendering thread
  // Linux EGL supports multiple independent contexts in different threads
  self->render_threads = g_hash_table_new_full(g_direct_hash, g_direct_equal,
                                               nullptr, [](gpointer data) {
                                                 delete static_cast<ThreadPool*>(data);
                                               });
  self->texture_registrar = nullptr;
  self->view = nullptr;
}

static void video_output_manager_dispose(GObject* object) {
  VideoOutputManager* self = VIDEO_OUTPUT_MANAGER(object);
  g_hash_table_unref(self->video_outputs);
  g_hash_table_unref(self->render_threads);
  G_OBJECT_CLASS(video_output_manager_parent_class)->dispose(object);
}

static void video_output_manager_class_init(VideoOutputManagerClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = video_output_manager_dispose;
}

VideoOutputManager* video_output_manager_new(
    FlTextureRegistrar* texture_registrar,
    FlView* view) {
  VideoOutputManager* video_output_manager = VIDEO_OUTPUT_MANAGER(
      g_object_new(video_output_manager_get_type(), nullptr));
  video_output_manager->texture_registrar = texture_registrar;
  video_output_manager->view = view;
  return video_output_manager;
}

void video_output_manager_create(VideoOutputManager* self,
                                 gint64 handle,
                                 VideoOutputConfiguration configuration,
                                 TextureUpdateCallback texture_update_callback,
                                 gpointer texture_update_callback_context,
                                 GDestroyNotify texture_update_callback_context_destroy_notify) {
  if (!g_hash_table_contains(self->video_outputs, GINT_TO_POINTER(handle))) {
    // Create a dedicated rendering thread for this video output
    // Each player gets its own thread to leverage Linux EGL multi-threading
    ThreadPool* render_thread = new ThreadPool(1);
    g_hash_table_insert(self->render_threads, GINT_TO_POINTER(handle), render_thread);
    
    g_autoptr(VideoOutput) video_output = video_output_new(
        self->texture_registrar, self->view, handle, configuration, render_thread);
    video_output_set_texture_update_callback(
      video_output, texture_update_callback, texture_update_callback_context,
      texture_update_callback_context_destroy_notify);
    g_hash_table_insert(self->video_outputs, GINT_TO_POINTER(handle),
                        g_object_ref(video_output));
  } else if (texture_update_callback_context_destroy_notify &&
             texture_update_callback_context) {
    texture_update_callback_context_destroy_notify(
        texture_update_callback_context);
  }
}

void video_output_manager_set_size(VideoOutputManager* self,
                                   gint64 handle,
                                   gint64 width,
                                   gint64 height) {
  if (g_hash_table_contains(self->video_outputs, GINT_TO_POINTER(handle))) {
    VideoOutput* video_output = VIDEO_OUTPUT(
        g_hash_table_lookup(self->video_outputs, GINT_TO_POINTER(handle)));
    video_output_set_size(video_output, width, height);
  }
}

void video_output_manager_dispose(VideoOutputManager* self, gint64 handle) {
  g_print("[VideoOutputManager] Disposing video output for handle: %ld\n", handle);
  if (g_hash_table_contains(self->video_outputs, GINT_TO_POINTER(handle))) {
    g_print("[VideoOutputManager] Found video output in hash table, removing...\n");
    
    // Get references before removal for logging
    VideoOutput* video_output = VIDEO_OUTPUT(
        g_hash_table_lookup(self->video_outputs, GINT_TO_POINTER(handle)));
    ThreadPool* thread_pool = static_cast<ThreadPool*>(
        g_hash_table_lookup(self->render_threads, GINT_TO_POINTER(handle)));
    g_print("[VideoOutputManager] video_output=%p, thread_pool=%p\n", video_output, thread_pool);
    
    // Must remove video_output first (triggers video_output_dispose which uses thread_pool)
    // Then remove thread pool after video_output cleanup is complete
    g_hash_table_remove(self->video_outputs, GINT_TO_POINTER(handle));
    g_print("[VideoOutputManager] video_output removed from hash table\n");
    
    // Now safe to remove the dedicated rendering thread
    // The thread pool will be deleted by hash table's value_destroy_func
    g_hash_table_remove(self->render_threads, GINT_TO_POINTER(handle));
    g_print("[VideoOutputManager] render_thread removed from hash table\n");
  } else {
    g_print("[VideoOutputManager] Video output NOT found in hash table\n");
  }
}
