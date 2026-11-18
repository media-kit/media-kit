// This file is a part of media_kit
// (https://github.com/media-kit/media-kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.
#ifndef MEDIA_KIT_PLATFORM_TASK_RUNNER_H_
#define MEDIA_KIT_PLATFORM_TASK_RUNNER_H_

#include <Windows.h>
#include <functional>
#include <mutex>
#include <queue>

namespace media_kit_video {

// Created and destroyed on the platform thread. Producers must be joined before
// destruction. The message-only window belongs to the plugin, not any view.
class PlatformTaskRunner {
 public:
  PlatformTaskRunner();
  ~PlatformTaskRunner();
  PlatformTaskRunner(const PlatformTaskRunner&) = delete;
  PlatformTaskRunner& operator=(const PlatformTaskRunner&) = delete;

  bool Post(std::function<void()> task);
  // Rejects new tasks and discards queued callbacks. Platform thread only.
  void Close();

 private:
  static constexpr UINT kTaskMessage = WM_APP + 1001;
  static LRESULT CALLBACK WindowProc(HWND window,
                                     UINT message,
                                     WPARAM wparam,
                                     LPARAM lparam);
  void Drain();
  HWND window_ = nullptr;
  std::mutex mutex_;
  std::queue<std::function<void()>> tasks_;
};

}  // namespace media_kit_video
#endif
