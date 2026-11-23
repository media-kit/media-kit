import Foundation
import CoreGraphics

// Deterministic doubles exercise the real VideoOutputManager without Flutter,
// a GPU, or libmpv. Each async boundary is advanced explicitly by a test.
public protocol FlutterTextureRegistry {}
final class Registry: FlutterTextureRegistry {}

public final class VideoOutput {
  public typealias TextureUpdateCallback = (Int64, CGSize) -> Void
  static var instances: [VideoOutput] = []
  let configuration: VideoOutputConfiguration
  let textureUpdateCallback: TextureUpdateCallback
  let initializationCompletion: (Bool) -> Void
  var pendingDisposals: [() -> Void] = []
  var size: (Int64?, Int64?)
  var disposeCount = 0
  var usesHardwareAcceleration: Bool { configuration.enableHardwareAcceleration }

  init(handle: Int64, configuration: VideoOutputConfiguration,
       registry: FlutterTextureRegistry,
       textureUpdateCallback: @escaping TextureUpdateCallback,
       initializationCompletion: @escaping (Bool) -> Void) {
    self.configuration = configuration
    self.textureUpdateCallback = textureUpdateCallback
    self.initializationCompletion = initializationCompletion
    size = (configuration.width, configuration.height)
    Self.instances.append(self)
  }

  func initialize(_ ready: Bool = true) {
    if ready { textureUpdateCallback(Int64(Self.instances.firstIndex { $0 === self }! + 1), .zero) }
    initializationCompletion(ready)
  }

  public func setSize(width: Int64?, height: Int64?) { size = (width, height) }
  public func dispose(completion: @escaping () -> Void) {
    disposeCount += 1
    pendingDisposals.append(completion)
  }
  func finishDisposal() {
    let callbacks = pendingDisposals
    pendingDisposals.removeAll()
    callbacks.forEach { $0() }
  }
}

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
  guard condition() else { fatalError(message) }
}

func config(_ hardware: Bool = true) -> VideoOutputConfiguration {
  VideoOutputConfiguration(width: 640, height: 360, enableHardwareAcceleration: hardware)
}

func create(_ manager: VideoOutputManager, handle: Int64 = 1, hardware: Bool = true) -> VideoOutput {
  var ready: Bool?
  manager.create(handle: handle, configuration: config(hardware), textureUpdateCallback: { _, _ in },
                 completion: { ready = $0 })
  let output = VideoOutput.instances.last!
  check(ready == nil, "Create must wait for context initialization")
  output.initialize()
  check(ready == true, "Create should complete after context and texture registration")
  return output
}

var passed = 0
func test(_ name: String, _ body: () -> Void) {
  VideoOutput.instances.removeAll()
  body()
  passed += 1
  print("PASS \(name)")
}

test("GPU -> software -> configured, including resize while old output drains") {
  let manager = VideoOutputManager(registry: Registry())
  let original = create(manager)
  var result: VideoOutputRenderingResult?
  manager.setSoftwareRendering(handle: 1, enabled: true) { result = $0 }
  check(result == nil && VideoOutput.instances.count == 1, "Wait for old context disposal")
  manager.setSize(handle: 1, width: 1280, height: 720)
  original.finishDisposal()
  let software = VideoOutput.instances.last!
  check(!software.configuration.enableHardwareAcceleration, "Replacement must be software")
  check(software.configuration.width == 1280 && software.configuration.height == 720, "Keep new dimensions")
  check(result == nil, "Wait for replacement context initialization")
  software.initialize()
  check(result == .changed && manager.softwareRenderingHandles == [1], "Report changed and track override")
  manager.setSoftwareRendering(handle: 1, enabled: true) { result = $0 }
  check(result == .unchanged && VideoOutput.instances.count == 2, "Repeated mode is a no-op")
  manager.setSoftwareRendering(handle: 1, enabled: false) { result = $0 }
  software.finishDisposal()
  let restored = VideoOutput.instances.last!
  check(restored.configuration.enableHardwareAcceleration, "Restore original GPU preference")
  restored.initialize()
  check(result == .changed && manager.softwareRenderingHandles.isEmpty, "Clear successful override")
}

test("User CPU preference is preserved and new-output override covers new handles") {
  let manager = VideoOutputManager(registry: Registry())
  manager.setSoftwareRenderingForNewOutputs(true)
  let originalCPU = create(manager, handle: 1, hardware: false)
  let overridden = create(manager, handle: 2)
  check(!overridden.configuration.enableHardwareAcceleration, "New handles inherit software override")
  check(manager.softwareRenderingHandles == [2], "Only original GPU preferences need restoration")
  var result: VideoOutputRenderingResult?
  manager.setSoftwareRendering(handle: 1, enabled: false) { result = $0 }
  check(result == .unchanged && originalCPU.disposeCount == 0, "Original CPU remains CPU")
  manager.setSoftwareRenderingForNewOutputs(false)
  check(create(manager, handle: 3).configuration.enableHardwareAcceleration, "Clearing default affects future handles")
  check(manager.softwareRenderingHandles == [2], "Existing override still needs explicit suspended transition")
}

test("Destroy during old-output disposal prevents replacement and delays completion") {
  let manager = VideoOutputManager(registry: Registry())
  let original = create(manager)
  var result: VideoOutputRenderingResult?
  var destroyed = 0
  manager.setSoftwareRendering(handle: 1, enabled: true) { result = $0 }
  manager.destroy(handle: 1) { destroyed += 1 }
  manager.destroy(handle: 1) { destroyed += 1 }
  check(destroyed == 0 && result == nil, "Do not release core while context drains")
  original.finishDisposal()
  check(result == .failed && destroyed == 2, "Complete all callers once")
  check(VideoOutput.instances.count == 1 && original.disposeCount == 1, "Do not create or double-dispose")
  _ = create(manager)
}

test("Destroy during replacement initialization drains new output before core release") {
  let manager = VideoOutputManager(registry: Registry())
  let original = create(manager)
  var result: VideoOutputRenderingResult?
  var destroyed = false
  manager.setSoftwareRendering(handle: 1, enabled: true) { result = $0 }
  original.finishDisposal()
  let replacement = VideoOutput.instances.last!
  manager.destroy(handle: 1) { destroyed = true }
  replacement.initialize()
  check(!destroyed && result == nil && replacement.disposeCount == 1, "Dispose initialized replacement before callbacks")
  replacement.finishDisposal()
  check(destroyed && result == .failed, "Drain replacement before reporting disposed")
}

test("Failed target rolls back before reporting failure") {
  let manager = VideoOutputManager(registry: Registry())
  let original = create(manager)
  var result: VideoOutputRenderingResult?
  manager.setSoftwareRendering(handle: 1, enabled: true) { result = $0 }
  original.finishDisposal()
  let failed = VideoOutput.instances.last!
  failed.initialize(false)
  check(result == nil && failed.disposeCount == 1, "Drain failed target")
  failed.finishDisposal()
  let rollback = VideoOutput.instances.last!
  check(rollback.configuration.enableHardwareAcceleration && result == nil, "Rebuild prior mode first")
  rollback.initialize()
  check(result == .failed && manager.softwareRenderingHandles.isEmpty, "Original renderer ready before failed callback")
}

test("Create failure and destroy during initialization never release core early") {
  let manager = VideoOutputManager(registry: Registry())
  var created: Bool?
  var destroyed = false
  manager.create(handle: 1, configuration: config(), textureUpdateCallback: { _, _ in },
                 completion: { created = $0 })
  let initializing = VideoOutput.instances.last!
  manager.destroy(handle: 1) { destroyed = true }
  initializing.initialize(false)
  check(created == nil && !destroyed, "Wait for failed context cleanup")
  initializing.finishDisposal()
  check(created == false && destroyed, "Fail once cleanup completes")
  _ = create(manager)
}

test("Overlapping operations report notReady without mutating the active output") {
  let manager = VideoOutputManager(registry: Registry())
  let original = create(manager)
  var duplicate: Bool?
  manager.create(handle: 1, configuration: config(), textureUpdateCallback: { _, _ in },
                 completion: { duplicate = $0 })
  check(duplicate == false && VideoOutput.instances.count == 1, "Reject duplicate context")
  manager.setSoftwareRendering(handle: 1, enabled: true) { _ in }
  var overlapping: VideoOutputRenderingResult?
  manager.setSoftwareRendering(handle: 1, enabled: false) { overlapping = $0 }
  check(overlapping == .notReady, "Report transient overlap before mutation")
  original.finishDisposal()
  VideoOutput.instances.last!.initialize()
  check(manager.softwareRenderingHandles == [1], "Rejected switch did not overwrite mode")
}

test("Background transition while disposal drains builds CPU and keeps restoration pending") {
  var foreground = true
  let manager = VideoOutputManager(registry: Registry(), canUseHardwareRendering: { foreground })
  manager.setSoftwareRenderingForNewOutputs(true)
  let software = create(manager)
  var result: VideoOutputRenderingResult?
  manager.setSoftwareRendering(handle: 1, enabled: false) { result = $0 }
  foreground = false
  software.finishDisposal()
  let replacement = VideoOutput.instances.last!
  check(!replacement.configuration.enableHardwareAcceleration, "Do not construct GL after backgrounding")
  replacement.initialize()
  check(result == .failed && manager.softwareRenderingHandles == [1], "Keep software override for next foreground retry")
  let count = VideoOutput.instances.count
  manager.setSoftwareRendering(handle: 1, enabled: false) { result = $0 }
  check(result == .failed && count == VideoOutput.instances.count, "Already-background restoration retains existing output")
  foreground = true
  manager.setSoftwareRendering(handle: 1, enabled: false) { result = $0 }
  replacement.finishDisposal()
  VideoOutput.instances.last!.initialize()
  check(result == .changed && manager.softwareRenderingHandles.isEmpty, "A later foreground restoration succeeds")
}

test("Failed target and failed rollback cannot masquerade as a ready unchanged output") {
  let manager = VideoOutputManager(registry: Registry())
  let original = create(manager)
  var result: VideoOutputRenderingResult?
  manager.setSoftwareRendering(handle: 1, enabled: true) { result = $0 }
  original.finishDisposal()
  let failed = VideoOutput.instances.last!
  failed.initialize(false)
  failed.finishDisposal()
  let rollback = VideoOutput.instances.last!
  rollback.initialize(false)
  check(result == .failed, "Both creation failures are reported")
  manager.setSoftwareRendering(handle: 1, enabled: false) { result = $0 }
  check(result == .failed, "Uninitialized output must never report unchanged")
  var disposed = false
  manager.destroy(handle: 1) { disposed = true }
  check(!disposed, "Dispose still drains failed rollback output")
  rollback.finishDisposal()
  check(disposed, "Failed output remains safely disposable")
}

test("Old output notifications are ignored after dispose and handle reuse") {
  let manager = VideoOutputManager(registry: Registry())
  var oldNotifications = 0
  manager.create(handle: 1, configuration: config(), textureUpdateCallback: { _, _ in oldNotifications += 1 })
  let original = VideoOutput.instances.last!
  original.initialize()
  manager.destroy(handle: 1) {}
  original.textureUpdateCallback(99, .zero)
  check(oldNotifications == 1, "Suppress callbacks as soon as disposal starts")
  original.finishDisposal()
  _ = create(manager)
  original.textureUpdateCallback(100, .zero)
  check(oldNotifications == 1, "Old instance cannot notify a replacement handle")
}

test("Initialization is temporarily notReady while missing or disposed handles fail") {
  let manager = VideoOutputManager(registry: Registry())
  var result: VideoOutputRenderingResult?
  manager.setSoftwareRendering(handle: 1, enabled: true) { result = $0 }
  check(result == .failed, "Missing handles must not be retried as initialization")
  manager.create(handle: 1, configuration: config(), textureUpdateCallback: { _, _ in })
  let initializing = VideoOutput.instances.last!
  manager.setSoftwareRendering(handle: 1, enabled: true) { result = $0 }
  check(result == .notReady, "Pending initialization is a retryable state")
  manager.destroy(handle: 1) {}
  manager.setSoftwareRendering(handle: 1, enabled: true) { result = $0 }
  check(result == .failed, "A disposed handle is permanent even while cleanup is busy")
  initializing.initialize()
  initializing.finishDisposal()
}

print("\(passed) rendering lifecycle tests passed")
