import CoreGraphics

#if canImport(Flutter)
  import Flutter
#elseif canImport(FlutterMacOS)
  import FlutterMacOS
#endif

public protocol ResizableTextureProtocol: NSObject, FlutterTexture {
  // Release the mpv render context before the player core is destroyed.
  func dispose()
  func resize(_ size: CGSize)
  func render(_ size: CGSize)
}

public extension ResizableTextureProtocol {
  // Existing external conformers may continue relying on deinitialization.
  // Built-in mpv textures override this to release their context explicitly.
  func dispose() {}
}
