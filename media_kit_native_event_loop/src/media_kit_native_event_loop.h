// This file is a part of media_kit (https://github.com/media-kit/media-kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>. All rights reserved.
// Use of this source code is governed by MIT license that can be found in the LICENSE file.

#ifndef MEDIA_KIT_NATIVE_EVENT_LOOP_H_
#define MEDIA_KIT_NATIVE_EVENT_LOOP_H_

#if defined(_WIN32)
#include <client.h>
#elif defined(ANDROID) || defined(__ANDROID__)
#include "include/client.h"
#elif defined(__linux__)
#include <mpv/client.h>
#elif defined(__APPLE__)
#include <mpv/client.h>
#endif

#include "dart_api_types.h"

#include <condition_variable>
#include <functional>
#include <future>
#include <iostream>
#include <mutex>
#include <thread>
#include <unordered_map>
#include <unordered_set>
#include <vector>

class MediaKitEventLoopHandler {
 public:
  static MediaKitEventLoopHandler& GetInstance();

  void Register(int64_t handle, void* post_c_object, int64_t send_port);

  void Notify(int64_t handle);

  void Dispose(int64_t handle, bool clean = true);

  void Initialize();

  MediaKitEventLoopHandler(const MediaKitEventLoopHandler&) = delete;

  void operator=(const MediaKitEventLoopHandler&) = delete;

 private:
  bool IsRegistered(int64_t handle);

  MediaKitEventLoopHandler();

  ~MediaKitEventLoopHandler();

  std::mutex mutex_;

  std::unordered_map<mpv_handle*, std::unique_ptr<std::mutex>> mutexes_;
  std::unordered_map<mpv_handle*, std::unique_ptr<std::thread>> threads_;
  std::unordered_map<mpv_handle*, std::unique_ptr<std::condition_variable>> condition_variables_;

  std::unordered_set<mpv_handle*> exit_handles_;
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

DLLEXPORT void MediaKitEventLoopHandlerRegister(int64_t handle, void* post_c_object, int64_t send_port);

DLLEXPORT void MediaKitEventLoopHandlerNotify(int64_t handle);

DLLEXPORT void MediaKitEventLoopHandlerDispose(int64_t handle);

DLLEXPORT void MediaKitEventLoopHandlerInitialize();

#ifdef __cplusplus
}
#endif

#endif  // MEDIA_KIT_NATIVE_EVENT_LOOP_H_
