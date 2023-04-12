// https://stackoverflow.com/questions/49043257/how-to-ensure-to-run-some-code-on-same-background-thread/49075382#49075382
class Worker {
  public typealias Job = () -> Void

  private let semaphore = DispatchSemaphore(value: 0)
  private let lock = NSRecursiveLock()
  private var thread: Thread!
  private var queue = [Job]()

  init() {
    thread = Thread(block: loop)
    thread.start()
  }

  public func enqueue(_ job: @escaping Job) {
    locked {
      queue.append(job)
    }

    semaphore.signal()
  }

  private func loop() {
    while true {
      semaphore.wait()

      let job = locked {
        queue.removeFirst()
      }

      job()
    }
  }

  private func locked<T>(do block: () -> T) -> T {
    lock.lock()
    defer {
      lock.unlock()
    }

    return block()
  }
}
