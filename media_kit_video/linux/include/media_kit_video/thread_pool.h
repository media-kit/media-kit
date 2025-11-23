// This file is a part of media_kit
// (https://github.com/media-kit/media-kit).
//
// Copyright © 2025 & onwards, Predidit.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

#ifndef THREAD_POOL_H_
#define THREAD_POOL_H_

#include <glib.h>
#include <functional>
#include <future>
#include <thread>
#include <queue>
#include <mutex>
#include <condition_variable>
#include <vector>
#include <memory>

class ThreadPool {
 public:
  explicit ThreadPool(size_t threads);
  ~ThreadPool();

  template <class F, class... Args>
  auto Post(F&& f, Args&&... args) -> std::future<typename std::invoke_result<F, Args...>::type>;

 private:
  std::vector<std::thread> workers_;
  std::queue<std::packaged_task<void()>> tasks_;

  std::mutex queue_mutex_;
  std::condition_variable condition_;
  std::condition_variable condition_producers_;
  bool stop_;
};

inline ThreadPool::ThreadPool(size_t threads) : stop_(false) {
  for (size_t i = 0; i < threads; i++) {
    workers_.emplace_back([this] {
      for (;;) {
        std::packaged_task<void()> task;
        {
          std::unique_lock<std::mutex> lock(this->queue_mutex_);
          this->condition_.wait(lock, [this] { return this->stop_ || !this->tasks_.empty(); });
          if (this->stop_ && this->tasks_.empty())
            return;
          task = std::move(this->tasks_.front());
          this->tasks_.pop();
          if (this->tasks_.empty()) {
            this->condition_producers_.notify_one();
          }
        }
        task();
      }
    });
    
    pthread_t thread_handle = workers_.back().native_handle();
    struct sched_param params;
    params.sched_priority = sched_get_priority_max(SCHED_FIFO);
    pthread_setschedparam(thread_handle, SCHED_FIFO, &params);
  }
}

template <class F, class... Args>
auto ThreadPool::Post(F&& f, Args&&... args) 
    -> std::future<typename std::invoke_result<F, Args...>::type> {
  using return_type = typename std::invoke_result<F, Args...>::type;
  
  auto task = std::make_shared<std::packaged_task<return_type()>>(
      std::bind(std::forward<F>(f), std::forward<Args>(args)...));
  
  std::future<return_type> res = task->get_future();
  {
    std::unique_lock<std::mutex> lock(queue_mutex_);
    if (stop_) {
      throw std::runtime_error("ThreadPool::Post on stopped ThreadPool");
    }
    tasks_.emplace([task]() { (*task)(); });
  }
  condition_.notify_one();
  return res;
}

inline ThreadPool::~ThreadPool() {
  g_print("[ThreadPool %p] Destroying - clearing task queue and stopping workers\n", this);
  size_t cleared_tasks = 0;
  {
    std::unique_lock<std::mutex> lock(queue_mutex_);
    // Don't wait for queue to empty - set stop flag immediately
    // This allows worker threads to exit even if tasks remain
    stop_ = true;
    // Clear any remaining tasks to free memory immediately
    cleared_tasks = tasks_.size();
    while (!tasks_.empty()) {
      tasks_.pop();
    }
  }
  g_print("[ThreadPool %p] Cleared %zu pending tasks, joining workers\n", this, cleared_tasks);
  condition_.notify_all();
  for (std::thread& worker : workers_) {
    if (worker.joinable()) {
      worker.join();
    }
  }
  g_print("[ThreadPool %p] Destroyed - all workers joined\n", this);
}

#endif  // THREAD_POOL_H_
