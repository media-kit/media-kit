// This file is a part of media_kit
// (https://github.com/alexmercerind/media_kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.
#include "include/media_kit_video/media_kit_video_plugin.h"

#include <gtk/gtk.h>

#include <flutter_linux/flutter_linux.h>

#define MEDIA_KIT_VIDEO_PLUGIN(obj)                                     \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), media_kit_video_plugin_get_type(), \
                              MediaKitVideoPlugin))

struct _MediaKitVideoPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(MediaKitVideoPlugin, media_kit_video_plugin, g_object_get_type())

static void media_kit_video_plugin_handle_method_call(
    MediaKitVideoPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;
  const gchar* method = fl_method_call_get_name(method_call);
  if (strcmp(method, "getPlatformVersion") == 0) {
    g_autoptr(FlValue) result = fl_value_new_null();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }
  fl_method_call_respond(method_call, response, nullptr);
}

static void media_kit_video_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(media_kit_video_plugin_parent_class)->dispose(object);
}

static void media_kit_video_plugin_class_init(MediaKitVideoPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = media_kit_video_plugin_dispose;
}

static void media_kit_video_plugin_init(MediaKitVideoPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel,
                           FlMethodCall* method_call,
                           gpointer user_data) {
  MediaKitVideoPlugin* plugin = MEDIA_KIT_VIDEO_PLUGIN(user_data);
  media_kit_video_plugin_handle_method_call(plugin, method_call);
}

void media_kit_video_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  MediaKitVideoPlugin* plugin = MEDIA_KIT_VIDEO_PLUGIN(
      g_object_new(media_kit_video_plugin_get_type(), nullptr));
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "com.alexmercerind/media_kit_video", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      channel, method_call_cb, g_object_ref(plugin), g_object_unref);
  g_object_unref(plugin);
}
