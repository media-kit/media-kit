// This file is a part of media_kit
// (https://github.com/alexmercerind/media_kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

#include "include/media_kit_video/media_kit_video_plugin.h"

#ifndef MEDIA_KIT_LIBS_NOT_FOUND

#include <gtk/gtk.h>

#include "include/media_kit_video/video_output_manager.h"

#define MEDIA_KIT_VIDEO_PLUGIN(obj)                                     \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), media_kit_video_plugin_get_type(), \
                              MediaKitVideoPlugin))

struct _MediaKitVideoPlugin {
  GObject parent_instance;
  FlMethodChannel* channel;
  VideoOutputManager* video_output_manager;
};

G_DEFINE_TYPE(MediaKitVideoPlugin, media_kit_video_plugin, g_object_get_type())

static void media_kit_video_plugin_handle_method_call(
    MediaKitVideoPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = NULL;
  const gchar* method = fl_method_call_get_name(method_call);
  if (g_strcmp0(method, "VideoOutputManager.Create") == 0) {
    FlValue* arguments = fl_method_call_get_args(method_call);
    FlValue* handle = fl_value_lookup_string(arguments, "handle");
    FlValue* width = fl_value_lookup_string(arguments, "width");
    FlValue* height = fl_value_lookup_string(arguments, "height");
    FlValue* enable_hardware_acceleration =
        fl_value_lookup_string(arguments, "enableHardwareAcceleration");
    gint64 handle_value =
        g_ascii_strtoll(fl_value_get_string(handle), NULL, 10);
    gint64 width_value = 0;
    gint64 height_value = 0;
    gboolean enable_hardware_acceleration_value =
        fl_value_get_bool(enable_hardware_acceleration);
    if (g_strcmp0(fl_value_get_string(width), "null") != 0 &&
        g_strcmp0(fl_value_get_string(height), "null") != 0) {
      width_value = g_ascii_strtoll(fl_value_get_string(width), NULL, 10);
      height_value = g_ascii_strtoll(fl_value_get_string(height), NULL, 10);
    }
    typedef struct _VideoOutputTextureUpdateCallbackData {
      FlMethodChannel* channel;
      gint64 handle;
    } VideoOutputTextureUpdateCallbackData;
    // TODO(@alexmercerind): Fix memory leak.
    VideoOutputTextureUpdateCallbackData* data =
        g_new0(VideoOutputTextureUpdateCallbackData, 1);
    data->channel = self->channel;
    data->handle = handle_value;
    video_output_manager_create(
        self->video_output_manager, handle_value, width_value, height_value,
        enable_hardware_acceleration_value,
        [](gint64 id, gint64 width, gint64 height, gpointer context) {
          auto data = (VideoOutputTextureUpdateCallbackData*)context;
          FlMethodChannel* channel = data->channel;
          gint64 handle = data->handle;
          FlValue* rect = fl_value_new_map();
          fl_value_set_string_take(rect, "left", fl_value_new_int(0));
          fl_value_set_string_take(rect, "top", fl_value_new_int(0));
          fl_value_set_string_take(rect, "width", fl_value_new_int(width));
          fl_value_set_string_take(rect, "height", fl_value_new_int(height));
          FlValue* result = fl_value_new_map();
          fl_value_set_string_take(result, "handle", fl_value_new_int(handle));
          fl_value_set_string_take(result, "id", fl_value_new_int(id));
          fl_value_set_string_take(result, "rect", rect);
          fl_method_channel_invoke_method(channel, "VideoOutput.Resize", result,
                                          NULL, NULL, NULL);
        },
        data);
    FlValue* result = fl_value_new_null();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (g_strcmp0(method, "VideoOutputManager.SetSize") == 0) {
    FlValue* arguments = fl_method_call_get_args(method_call);
    FlValue* handle = fl_value_lookup_string(arguments, "handle");
    FlValue* width = fl_value_lookup_string(arguments, "width");
    FlValue* height = fl_value_lookup_string(arguments, "height");
    gint64 handle_value =
        g_ascii_strtoll(fl_value_get_string(handle), NULL, 10);
    gint64 width_value = 0;
    gint64 height_value = 0;
    if (g_strcmp0(fl_value_get_string(width), "null") != 0 &&
        g_strcmp0(fl_value_get_string(height), "null") != 0) {
      width_value = g_ascii_strtoll(fl_value_get_string(width), NULL, 10);
      height_value = g_ascii_strtoll(fl_value_get_string(height), NULL, 10);
    }
    g_print("%ld %ld\n", width_value, height_value);
    video_output_manager_set_size(self->video_output_manager, handle_value,
                                  width_value, height_value);
    FlValue* result = fl_value_new_null();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (g_strcmp0(method, "VideoOutputManager.Dispose") == 0) {
    FlValue* arguments = fl_method_call_get_args(method_call);
    FlValue* handle = fl_value_lookup_string(arguments, "handle");
    gint64 handle_value =
        g_ascii_strtoll(fl_value_get_string(handle), NULL, 10);
    video_output_manager_dispose(self->video_output_manager, handle_value);
    FlValue* result = fl_value_new_null();
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

static void media_kit_video_plugin_init(MediaKitVideoPlugin* self) {
  self->channel = NULL;
  self->video_output_manager = NULL;
}

static void method_call_cb(FlMethodChannel* channel,
                           FlMethodCall* method_call,
                           gpointer user_data) {
  MediaKitVideoPlugin* plugin = MEDIA_KIT_VIDEO_PLUGIN(user_data);
  media_kit_video_plugin_handle_method_call(plugin, method_call);
}

static MediaKitVideoPlugin* media_kit_video_plugin_new(
    FlPluginRegistrar* registrar) {
  MediaKitVideoPlugin* self = MEDIA_KIT_VIDEO_PLUGIN(
      g_object_new(media_kit_video_plugin_get_type(), nullptr));
  g_autoptr(FlMethodCodec) codec =
      FL_METHOD_CODEC(fl_standard_method_codec_new());
  self->channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "com.alexmercerind/media_kit_video", codec);
  fl_method_channel_set_method_call_handler(self->channel, method_call_cb, self,
                                            g_object_unref);
  FlTextureRegistrar* texture_registrar =
      fl_plugin_registrar_get_texture_registrar(registrar);
  // Create new |VideoOutputManager| instance. Pass |texture_registrar| as
  // reference.
  self->video_output_manager = video_output_manager_new(texture_registrar);
  return self;
}

void media_kit_video_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  media_kit_video_plugin_new(registrar);
}

#else

#include <iostream>

void media_kit_video_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  std::cout << "media_kit: WARNING: package:media_kit_libs_*** not found."
            << std::endl;
}

#endif
