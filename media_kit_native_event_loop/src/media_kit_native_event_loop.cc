// This file is a part of media_kit (https://github.com/media-kit/media-kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>. All rights reserved.
// Use of this source code is governed by MIT license that can be found in the LICENSE file.

#include "media_kit_native_event_loop.h"

#if defined(__APPLE__)
#include "signal_recovery.h"
#endif

MediaKitEventLoopHandler& MediaKitEventLoopHandler::GetInstance() {
  static MediaKitEventLoopHandler instance;
  return instance;
}

void MediaKitEventLoopHandler::Register(int64_t handle, void* post_c_object, int64_t send_port) {
  if (!IsRegistered(handle)) {
    std::lock_guard<std::mutex> lock(mutex_);

    auto context = reinterpret_cast<mpv_handle*>(handle);

    if (mutexes_.find(context) == mutexes_.end()) {
      mutexes_.emplace(std::make_pair(context, std::make_unique<std::mutex>()));
    }
    if (condition_variables_.find(context) == condition_variables_.end()) {
      condition_variables_.emplace(std::make_pair(context, std::make_unique<std::condition_variable>()));
    }

    auto thread = std::make_unique<std::thread>([&, context, post_c_object, send_port]() {
      for (;;) {
        mutex_.lock();

        {
          // This block is to ensure we free the context-specific mutex
          // before trying to re-lock the global mutex and check if we should exit.
          // The global mutex must always be acquired before the context-specific
          // mutex to avoid a race condition (lock order inversion).
          std::unique_lock<std::mutex> l(*mutexes_[context]);

          auto condition_variable = condition_variables_[context].get();

          mutex_.unlock();

          auto event = mpv_wait_event(context, -1);

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
          auto fn = reinterpret_cast<bool (*)(Dart_Port, Dart_CObject*)>(post_c_object);
          if (event->event_id != MPV_EVENT_NONE) {
  #if defined(__APPLE__)
            signal_try(label) {
              fn(send_port, &event_object);
            }
            signal_catch(label) {}
            signal_end(label)
  #else
            fn(send_port, &event_object);
  #endif
          }

          // Interpret the posted event in Dart. Wait for |Notify| to be called.
          condition_variable->wait(l);
        }

        // Check if this |handle| has been marked to exit.
        mutex_.lock();
        auto exit = exit_handles_.find(context) != exit_handles_.end();
        mutex_.unlock();
        if (exit) {
          std::cout << "MediaKitEventLoopHandler::Register: std::thread exit: " << reinterpret_cast<int64_t>(context)
                    << std::endl;
          break;
        }
      }
    });

    threads_.emplace(std::make_pair(context, std::move(thread)));
  }
}

void MediaKitEventLoopHandler::Notify(int64_t handle) {
  if (IsRegistered(handle)) {
    std::lock_guard<std::mutex> lock(mutex_);

    auto context = reinterpret_cast<mpv_handle*>(handle);

    std::unique_lock<std::mutex> l(*mutexes_[context]);
    condition_variables_[context]->notify_all();
  }
}

void MediaKitEventLoopHandler::Dispose(int64_t handle, bool clean) {
  auto context = reinterpret_cast<mpv_handle*>(handle);
  if (IsRegistered(handle)) {
    mutex_.lock();
    // Mark this |handle| to exit.
    exit_handles_.insert(context);
    mutex_.unlock();

    // Break out of previous possible |mpv_wait_event|.
    mpv_wakeup(context);
    // Break out of possible |std::condition_variable| wait.
    Notify(handle);

    // Wait for the |std::thread| to exit.
    try {
      mutex_.lock();
      auto thread = threads_[context].get();
      mutex_.unlock();
      if (thread->joinable()) {
        thread->join();
      }
    } catch (std::system_error& e) {
      std::cout << "MediaKitEventLoopHandler::Dispose: " << e.code() << " " << e.what() << std::endl;
    }

    if (!clean) {
      return;
    }

    std::thread([&, context]() {
      // In extreme usage, |std::thread::join| does not stop the |std::mutex| from being released upon exit, resulting
      // in "mutex destroyed while busy" on Windows. Destroying resources after a voluntary delay of 5 seconds.
      std::this_thread::sleep_for(std::chrono::seconds(5));

      std::lock_guard<std::mutex> lock(mutex_);

#ifndef _WIN32
      // Apparently destroying |std::mutex| from Windows' MSVC is a mess. I rather just leak it.
      // https://github.com/media-kit/media-kit/issues/9#issuecomment-1596120224
      mutexes_.erase(context);
#endif

      threads_.erase(context);
      condition_variables_.erase(context);

      exit_handles_.erase(context);
    }).detach();
  }

  std::cout << "MediaKitEventLoopHandler::Dispose: " << handle << std::endl;
}

void MediaKitEventLoopHandler::Initialize() {
  auto contexts = std::vector<mpv_handle*>();

  mutex_.lock();
  for (auto& [context, _] : threads_) {
    contexts.push_back(context);
  }
  mutex_.unlock();

  for (auto& context : contexts) {
    Dispose(reinterpret_cast<int64_t>(context));
    mpv_command_string(context, "quit");
  }
}

bool MediaKitEventLoopHandler::IsRegistered(int64_t handle) {
  std::lock_guard<std::mutex> lock(mutex_);
  return mutexes_.find(reinterpret_cast<mpv_handle*>(handle)) != mutexes_.end() &&
         threads_.find(reinterpret_cast<mpv_handle*>(handle)) != threads_.end() &&
         condition_variables_.find(reinterpret_cast<mpv_handle*>(handle)) != condition_variables_.end();
}

MediaKitEventLoopHandler::MediaKitEventLoopHandler() {
#if defined(__APPLE__)
  signal_catch_init();
#endif
}

MediaKitEventLoopHandler::~MediaKitEventLoopHandler() {
  auto contexts = std::vector<mpv_handle*>();

  mutex_.lock();
  for (auto& [context, _] : threads_) {
    contexts.push_back(context);
  }
  mutex_.unlock();

  for (auto& context : contexts) {
    // Here, clean argument is `false` for avoiding redundant removal of entries from |mutexes_|, |threads_| &
    // |condition_variables_| |std::unordered_map|s. Since, this destructor is only called upon process termination, it
    // is not an issue.
    // Specifically on Windows, this is done to prevent a crash because the detached thread (used to clean up the
    // entries inside |Dispose| after a voluntary delay) fails to launch/clean-before-exit. Overall, this solution
    // ensures a graceful exit.
    Dispose(reinterpret_cast<int64_t>(context), false);
  }
}

// ---------------------------------------------------------------------------
// C API for access using dart:ffi
// ---------------------------------------------------------------------------

void MediaKitEventLoopHandlerRegister(int64_t handle, void* post_c_object, int64_t send_port) {
  MediaKitEventLoopHandler::GetInstance().Register(handle, post_c_object, send_port);
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
