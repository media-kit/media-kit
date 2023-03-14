import Cocoa
import FlutterMacOS

public protocol ResizableTextureProtocol: NSObject, FlutterTexture {
  func resize(_ size: CGSize)
  func render(_ size: CGSize)
  func dispose()
}
