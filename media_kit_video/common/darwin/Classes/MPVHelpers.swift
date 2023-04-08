public enum MPVHelpers {
  public static func checkError(_ status: CInt) {
    if status < 0 {
      NSLog("MPVHelpers: error: \(MPVLib.mpv_error_string(status))")
      exit(1)
    }
  }
}
