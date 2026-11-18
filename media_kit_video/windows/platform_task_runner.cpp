// This file is a part of media_kit
// (https://github.com/media-kit/media-kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.
#include "platform_task_runner.h"

#include <stdexcept>
#include <utility>

namespace media_kit_video {

PlatformTaskRunner::PlatformTaskRunner() {
  HMODULE module = nullptr;
  if (!GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                              GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                          reinterpret_cast<LPCWSTR>(&WindowProc), &module)) {
    throw std::runtime_error("Cannot locate platform task runner module");
  }
  WNDCLASSW window_class{};
  window_class.lpfnWndProc = WindowProc;
  window_class.hInstance = module;
  window_class.lpszClassName = L"MediaKitVideoPlatformTaskRunner";
  if (!RegisterClassW(&window_class) &&
      GetLastError() != ERROR_CLASS_ALREADY_EXISTS) {
    throw std::runtime_error("Cannot register platform task window class");
  }
  window_ = CreateWindowExW(0, window_class.lpszClassName, L"", 0, 0, 0, 0, 0,
                            HWND_MESSAGE, nullptr, module, this);
  if (!window_) {
    throw std::runtime_error("Cannot create platform task window");
  }
}

PlatformTaskRunner::~PlatformTaskRunner() {
  Close();
}

bool PlatformTaskRunner::Post(std::function<void()> task) {
  std::lock_guard<std::mutex> lock(mutex_);
  if (!window_)
    return false;
  // Enqueue only when a wakeup was accepted. The platform thread cannot drain
  // the queue until this lock is released.
  if (!PostMessageW(window_, kTaskMessage, 0, 0))
    return false;
  tasks_.push(std::move(task));
  return true;
}

void PlatformTaskRunner::Close() {
  HWND window;
  std::queue<std::function<void()>> discarded;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    window = window_;
    window_ = nullptr;
    tasks_.swap(discarded);
  }
  if (window)
    DestroyWindow(window);
}

LRESULT CALLBACK PlatformTaskRunner::WindowProc(HWND window,
                                                UINT message,
                                                WPARAM wparam,
                                                LPARAM lparam) {
  if (message == WM_NCCREATE) {
    auto* create = reinterpret_cast<CREATESTRUCTW*>(lparam);
    SetWindowLongPtrW(window, GWLP_USERDATA,
                      reinterpret_cast<LONG_PTR>(create->lpCreateParams));
  }
  auto* runner = reinterpret_cast<PlatformTaskRunner*>(
      GetWindowLongPtrW(window, GWLP_USERDATA));
  if (message == kTaskMessage && runner) {
    runner->Drain();
    return 0;
  }
  if (message == WM_NCDESTROY)
    SetWindowLongPtrW(window, GWLP_USERDATA, 0);
  return DefWindowProcW(window, message, wparam, lparam);
}

void PlatformTaskRunner::Drain() {
  while (true) {
    std::function<void()> task;
    {
      std::lock_guard<std::mutex> lock(mutex_);
      if (!window_ || tasks_.empty())
        return;
      task = std::move(tasks_.front());
      tasks_.pop();
    }
    try {
      task();
    } catch (...) {
      // Never unwind a C++ exception through the Win32 window procedure.
    }
  }
}

}  // namespace media_kit_video
