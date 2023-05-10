// This file is a part of media_kit
// (https://github.com/alexmercerind/media_kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

#include "media_kit_native_event_loop.h"

MediaKitEventLoopHandler& MediaKitEventLoopHandler::GetInstance() {
  static MediaKitEventLoopHandler instance;
  return instance;
}

void MediaKitEventLoopHandler::Register(int64_t handle,
                                        void* post_c_object,
                                        int64_t send_port) {
  std::thread([&, handle, post_c_object, send_port]() {
    auto context = reinterpret_cast<mpv_handle*>(handle);

    for (;;) {
      {
        std::lock_guard<std::mutex> lock(mutex_);
        promises_[context] = std::promise<void>();
      }

      auto event = mpv_wait_event(context, -1);

      {
        std::lock_guard<std::mutex> lock(mutex_);
        if (disposed_.find(context) != disposed_.end()) {
          // The |context| was marked as |Dispose|'d.
          promises_.erase(context);
          // Notify |Dispose| to return.
          try {
            disposed_[context].set_value();
          } catch (...) {
          }
          std::cout << "MediaKitEventLoopHandler::Register: std::thread exit: "
                    << reinterpret_cast<int64_t>(context) << std::endl;
          break;
        }
      }

      // [mpv_handle*, mpv_event*]
      Dart_CObject mpv_handle_object;
      mpv_handle_object.type = Dart_CObject_kInt64;
      mpv_handle_object.value.as_int64 = reinterpret_cast<int64_t>(context);
      Dart_CObject mpv_event_object;
      mpv_event_object.type = Dart_CObject_kInt64;
      mpv_event_object.value.as_int64 = reinterpret_cast<int64_t>(event);
      Dart_CObject* value_objects[] = {&mpv_handle_object, &mpv_event_object};
      Dart_CObject event_object;
      event_object.type = Dart_CObject_kArray;
      event_object.value.as_array.length = 2;
      event_object.value.as_array.values = value_objects;

      // Post to Dart.
      auto fn =
          reinterpret_cast<bool (*)(Dart_Port, Dart_CObject*)>(post_c_object);
      fn(send_port, &event_object);

      // Interpret the event inside Dart.
      // Wait for |MediaKitEventLoopHandler::Notify| to be called.
      promises_[context].get_future().wait();
    }
  }).detach();
}

void MediaKitEventLoopHandler::Notify(int64_t handle) {
  auto context = reinterpret_cast<mpv_handle*>(handle);
  if (disposed_.find(context) != disposed_.end()) {
    // The |context| was marked as |Dispose|'d.
    return;
  }
  {
    std::lock_guard<std::mutex> lock(mutex_);
    // Allow next |mpv_wait_event| to be called.
    try {
      promises_[context].set_value();
    } catch (...) {
    }
  }
}

void MediaKitEventLoopHandler::Dispose(int64_t handle) {
  auto context = reinterpret_cast<mpv_handle*>(handle);
  {
    std::lock_guard<std::mutex> lock(mutex_);
    // Break out of the possible |promises_| wait on the Dart side.
    try {
      promises_[context].set_value();
    } catch (...) {
    }
    // Mark the |context| as |Dispose|'d.
    disposed_[context] = std::promise<void>();
  }
  // Break out of the possible |mpv_wait_event| call.
  mpv_wakeup(context);
  // Wait for the event loop |std::thread| of that |context| to exit.
  disposed_[context].get_future().wait_for(std::chrono::seconds(1));
}

void MediaKitEventLoopHandler::Initialize() {
  auto contexts = std::vector<mpv_handle*>{};
  {
    std::lock_guard<std::mutex> lock(mutex_);
    for (auto& [context, _] : promises_) {
      contexts.push_back(context);
    }
  }
  for (auto& context : contexts) {
    // Release the |MediaKitEventLoopHandler| resources.
    Dispose(reinterpret_cast<int64_t>(context));
    // Release the internal libmpv resources.
    mpv_command_string(context, "set vid no");
    mpv_command_string(context, "set aid no");
    mpv_command_string(context, "set sid no");
    mpv_command_string(context, "quit");
  }
  {
    std::lock_guard<std::mutex> lock(mutex_);
    promises_.clear();
    disposed_.clear();
  }
}

MediaKitEventLoopHandler::MediaKitEventLoopHandler() {}

MediaKitEventLoopHandler::~MediaKitEventLoopHandler() {}

// ---------------------------------------------------------------------------
// C API for access using dart:ffi
// ---------------------------------------------------------------------------

void MediaKitEventLoopHandlerRegister(int64_t handle,
                                      void* post_c_object,
                                      int64_t send_port) {
  MediaKitEventLoopHandler::GetInstance().Register(handle, post_c_object,
                                                   send_port);
}

void MediaKitEventLoopHandlerNotify(int64_t handle) {
  MediaKitEventLoopHandler::GetInstance().Notify(handle);
}

void MediaKitEventLoopHandlerDispose(int64_t handle) {
  MediaKitEventLoopHandler::GetInstance().Dispose(handle);
}

void MediaKitEventLoopHandlerInitialize() {
  MediaKitEventLoopHandler::GetInstance().Initialize();
}
