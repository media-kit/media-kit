public class MPVHelpers {
  static public func checkError(_ status: CInt) {
    if status < 0 {
      NSLog("MPVHelpers: error: \(mpv_error_string(status) as Any)")
      exit(1)
    }
  }
}
