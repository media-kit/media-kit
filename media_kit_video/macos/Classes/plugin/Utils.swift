public class Utils: NSObject, UtilsProtocol {
  private let window: NSWindow

  init(_ window: NSWindow) {
    self.window = window
  }

  public func enterNativeFullscreen() {
    if !window.styleMask.contains(.fullScreen) {
      window.toggleFullScreen(nil)
    }
  }

  public func exitNativeFullscreen() {
    if window.styleMask.contains(.fullScreen) {
      window.toggleFullScreen(nil)
    }
  }
}
