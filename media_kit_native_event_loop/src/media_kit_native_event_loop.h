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
// TODO(@alexmercerind): GNU/Linux libmpv headers.
#elif __APPLE__
// TODO(@alexmercerind): macOS libmpv headers.
#endif
#include "dart_api/dart_api_dl.h"

class MediaKitEventLoopHandler {
 public:
  static MediaKitEventLoopHandler& GetInstance();
  MediaKitEventLoopHandler(const MediaKitEventLoopHandler&) = delete;
  void operator=(const MediaKitEventLoopHandler&) = delete;

 private:
  MediaKitEventLoopHandler();
  ~MediaKitEventLoopHandler() = default;
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

#ifdef __cplusplus
}
#endif

#endif  // MEDIA_KIT_NATIVE_EVENT_LOOP_H_
