// This file is a part of media_kit
// (https://github.com/alexmercerind/media_kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

#ifndef MEDIA_KIT_NATIVE_EVENT_LOOP_H_
#define MEDIA_KIT_NATIVE_EVENT_LOOP_H_

#ifdef _WIN32
#include <client.h>
#elif __linux__
#include <mpv/client.h>
#elif __APPLE__
#include <mpv/client.h>
#endif

#include "dart_api_types.h"

#include <future>
#include <functional>
#include <unordered_map>

class MediaKitEventLoopHandler {
 public:
  static MediaKitEventLoopHandler& GetInstance();

  void Register(int64_t handle, void* post_c_object, int64_t send_port);

  void Notify(int64_t handle);

  MediaKitEventLoopHandler(const MediaKitEventLoopHandler&) = delete;

  void operator=(const MediaKitEventLoopHandler&) = delete;

 private:
  MediaKitEventLoopHandler();

  ~MediaKitEventLoopHandler();
  std::unordered_map<mpv_handle*, std::mutex> mutexes_;
  // std::promise(s) are working very well & look more readable. I'm tired of
  // dealing with std::condition_variable(s) which would eventually lead to
  // deadlocks or stop working after a while.
  std::unordered_map<mpv_handle*, std::promise<void>> promises_;
};

// ---------------------------------------------------------------------------
// C API for access using dart:ffi
// ---------------------------------------------------------------------------

#ifdef _WIN32
#define DLLEXPORT __declspec(dllexport)
#else
#define DLLEXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

DLLEXPORT void MediaKitEventLoopHandlerRegister(int64_t handle,
                                                void* post_c_object,
                                                int64_t send_port);

DLLEXPORT void MediaKitEventLoopHandlerNotify(int64_t handle);

#ifdef __cplusplus
}
#endif

#endif  // MEDIA_KIT_NATIVE_EVENT_LOOP_H_
