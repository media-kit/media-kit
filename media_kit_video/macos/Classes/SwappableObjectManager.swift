public class SwappableObjectManager<T> {
  private let lock: NSRecursiveLock = NSRecursiveLock()
  private var available: [T]
  private var ready: [T] = []
  private var _current: T?

  init(objects: [T], skipCheckArgs: Bool = false) {
    if !skipCheckArgs {
      SwappableObjectManager.checkArgs(objects)
    }

    available = objects
  }

  public func reinit(objects: [T], skipCheckArgs: Bool = false) {
    if !skipCheckArgs {
      SwappableObjectManager.checkArgs(objects)
    }

    lock.lock()
    defer {
      lock.unlock()
    }

    available = objects
    ready = []
    _current = nil
  }

  public func nextAvailable() -> T? {
    lock.lock()
    defer {
      lock.unlock()
    }

    let object: T? =
      available.count > 0
      ? available.removeFirst()
      : nil

    return object
  }

  public func pushAsReady(_ object: T) {
    lock.lock()
    defer {
      lock.unlock()
    }

    ready.append(object)
    updateCurrent()
  }

  public var current: T? {
    lock.lock()
    defer {
      lock.unlock()
    }

    return _current
  }

  private func updateCurrent() {
    lock.lock()
    defer {
      lock.unlock()
    }

    let next: T? =
      ready.count > 0
      ? ready.removeFirst()
      : nil

    if next == nil {
      return
    }

    let old: T? = _current
    _current = next

    if old == nil {
      return
    }

    available.append(old!)
  }

  static private func checkArgs(_ objects: [T]) {
    if objects.count < 2 {
      NSLog("SwappableObjectManager: require at least two objects to work")
    }
  }
}
