import CoreGraphics

#if canImport(Flutter)
  import Flutter
#elseif canImport(FlutterMacOS)
  import FlutterMacOS
#endif

public protocol ResizableTextureProtocol: NSObject, FlutterTexture {
  func resize(_ size: CGSize)
  // Returns whether a new frame was drawn.
  func render(_ size: CGSize) -> Bool
  // Frees the mpv render context; the texture renders nothing afterwards.
  func dispose()
}
