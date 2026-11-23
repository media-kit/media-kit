import Foundation
#if canImport(UIKit)
  import UIKit
#endif

#if canImport(Flutter)
  import Flutter
#elseif canImport(FlutterMacOS)
  import FlutterMacOS
#endif

/// The result of a native rendering-mode request. All callbacks run on the
/// platform thread. A changed output has an initialized context and texture ID.
public enum VideoOutputRenderingResult {
  case unchanged
  case changed
  /// Initialization or another rendering transition is still in progress.
  case notReady
  case failed
}

public class VideoOutputManager: NSObject {
  private final class Entry {
    let configuration: VideoOutputConfiguration
    let textureUpdateCallback: VideoOutput.TextureUpdateCallback
    var width: Int64?
    var height: Int64?
    var softwareRendering: Bool
    var output: VideoOutput?
    var busy = true
    var ready = false
    var destroyed = false
    var destroyCompletions: [() -> Void] = []

    init(configuration: VideoOutputConfiguration,
         softwareRendering: Bool,
         textureUpdateCallback: @escaping VideoOutput.TextureUpdateCallback) {
      self.configuration = configuration
      self.textureUpdateCallback = textureUpdateCallback
      width = configuration.width
      height = configuration.height
      self.softwareRendering = softwareRendering
    }

    func configuration(softwareRendering: Bool) -> VideoOutputConfiguration {
      VideoOutputConfiguration(
        width: width,
        height: height,
        enableHardwareAcceleration: configuration.enableHardwareAcceleration && !softwareRendering
      )
    }
  }

  private let registry: FlutterTextureRegistry
  private var videoOutputs = [Int64: Entry]()
  private var softwareRenderingForNewOutputs = false
  private let canUseHardwareRendering: () -> Bool

  init(registry: FlutterTextureRegistry, canUseHardwareRendering: (() -> Bool)? = nil) {
    self.registry = registry
    self.canUseHardwareRendering = canUseHardwareRendering ?? {
      #if canImport(UIKit)
        return UIApplication.shared.applicationState == .active
      #else
        return true
      #endif
    }
  }

  /// Applies only to subsequently created outputs. Existing outputs must be
  /// changed with setSoftwareRendering after their video tracks are suspended.
  public func setSoftwareRenderingForNewOutputs(_ enabled: Bool) {
    assert(Thread.isMainThread)
    softwareRenderingForNewOutputs = enabled
  }

  /// Outputs whose original GPU preference is currently overridden. Includes
  /// outputs being initialized so callers can retry restoration when ready.
  public var softwareRenderingHandles: [Int64] {
    assert(Thread.isMainThread)
    return videoOutputs.compactMap { handle, entry in
      !entry.destroyed && entry.configuration.enableHardwareAcceleration && entry.softwareRendering
        ? handle : nil
    }
  }

  public func create(
    handle: Int64,
    configuration: VideoOutputConfiguration,
    textureUpdateCallback: @escaping VideoOutput.TextureUpdateCallback,
    completion: @escaping (Bool) -> Void = { _ in }
  ) {
    assert(Thread.isMainThread)
    // A second context for the same core is invalid, including while its
    // previous output is still being asynchronously destroyed.
    guard videoOutputs[handle] == nil else { completion(false); return }
    let entry = Entry(configuration: configuration,
                      softwareRendering: softwareRenderingForNewOutputs,
                      textureUpdateCallback: textureUpdateCallback)
    videoOutputs[handle] = entry
    makeOutput(handle: handle, entry: entry, softwareRendering: entry.softwareRendering) { ready in
      entry.busy = false
      guard ready && !entry.destroyed else {
        entry.destroyed = true
        // Finish disposal before reporting failure, allowing the caller to
        // release the player's mpv core as soon as its Create future fails.
        entry.destroyCompletions.append { completion(false) }
        self.finishDestroy(handle: handle, entry: entry)
        return
      }
      entry.ready = true
      entry.softwareRendering = entry.configuration.enableHardwareAcceleration &&
        !(entry.output?.usesHardwareAcceleration ?? false)
      completion(true)
    }
  }

  public func setSize(handle: Int64, width: Int64?, height: Int64?) {
    assert(Thread.isMainThread)
    guard let entry = videoOutputs[handle], !entry.destroyed else { return }
    entry.width = width
    entry.height = height
    entry.output?.setSize(width: width, height: height)
  }

  /// Caller must suspend the video's `vid` before this call, and restore it
  /// after completion (including failure). The player and decoder are retained.
  /// Requests overlapping another initialization/transition return notReady;
  /// unknown, disposed, or unsuccessfully recovered outputs return failed.
  public func setSoftwareRendering(
    handle: Int64,
    enabled: Bool,
    completion: @escaping (VideoOutputRenderingResult) -> Void
  ) {
    assert(Thread.isMainThread)
    guard let entry = videoOutputs[handle], !entry.destroyed else { completion(.failed); return }
    guard !entry.busy else { completion(.notReady); return }
    guard entry.ready, let output = entry.output else { completion(.failed); return }
    let previous = entry.softwareRendering
    // If GPU was disabled by the user, both modes have the same renderer.
    guard entry.configuration.enableHardwareAcceleration && previous != enabled else {
      entry.softwareRendering = enabled
      completion(.unchanged)
      return
    }
    // A restoration requested in background must preserve the existing CPU
    // context. The caller can retry once the application becomes active.
    guard enabled || self.canUseHardwareRendering() else { completion(.failed); return }
    entry.busy = true
    entry.output = nil
    output.dispose {
      guard !entry.destroyed else {
        self.finishTransition(handle: handle, entry: entry, result: .failed, completion: completion)
        return
      }
      let targetSoftware = enabled || !self.canUseHardwareRendering()
      self.makeOutput(handle: handle, entry: entry, softwareRendering: targetSoftware) { ready in
        if ready && !entry.destroyed {
          entry.softwareRendering = entry.configuration.enableHardwareAcceleration &&
            !(entry.output?.usesHardwareAcceleration ?? false)
          entry.ready = true
          let result: VideoOutputRenderingResult = entry.softwareRendering == enabled ? .changed : .failed
          self.finishTransition(handle: handle, entry: entry, result: result, completion: completion)
          return
        }
        guard !entry.destroyed else {
          self.finishTransition(handle: handle, entry: entry, result: .failed, completion: completion)
          return
        }
        // Try to recover the prior renderer before asking the caller to
        // restore vid. A failed request must not leave a discarded context.
        let failedOutput = entry.output
        entry.output = nil
        failedOutput?.dispose {
          guard !entry.destroyed else {
            self.finishTransition(handle: handle, entry: entry, result: .failed, completion: completion)
            return
          }
          let rollbackSoftware = previous || !self.canUseHardwareRendering()
          self.makeOutput(handle: handle, entry: entry, softwareRendering: rollbackSoftware) { recovered in
            entry.ready = recovered
            entry.softwareRendering = entry.configuration.enableHardwareAcceleration &&
              !(entry.output?.usesHardwareAcceleration ?? false)
            self.finishTransition(handle: handle, entry: entry, result: .failed, completion: completion)
          }
        }
      }
    }
  }

  private func makeOutput(handle: Int64, entry: Entry, softwareRendering: Bool,
                          completion: @escaping (Bool) -> Void) {
    entry.output = VideoOutput(
      handle: handle,
      configuration: entry.configuration(softwareRendering: softwareRendering),
      registry: registry,
      textureUpdateCallback: { [weak entry] textureId, size in
        guard let entry = entry, !entry.destroyed else { return }
        entry.textureUpdateCallback(textureId, size)
      },
      initializationCompletion: { ready in
        // A size update may have arrived while the old output was draining.
        entry.output?.setSize(width: entry.width, height: entry.height)
        completion(ready)
      }
    )
  }

  private func finishTransition(handle: Int64, entry: Entry,
                                result: VideoOutputRenderingResult,
                                completion: @escaping (VideoOutputRenderingResult) -> Void) {
    entry.busy = false
    if entry.destroyed {
      // Drain a replacement that finished creating during disposal before
      // allowing either caller to release or reuse the player's handle.
      entry.destroyCompletions.append { completion(.failed) }
      finishDestroy(handle: handle, entry: entry)
    } else {
      completion(result)
    }
  }

  public func destroy(handle: Int64, completion: @escaping () -> Void = {}) {
    assert(Thread.isMainThread)
    guard let entry = videoOutputs[handle] else { completion(); return }
    entry.destroyed = true
    entry.destroyCompletions.append(completion)
    finishDestroy(handle: handle, entry: entry)
  }

  private func finishDestroy(handle: Int64, entry: Entry) {
    guard entry.destroyed && !entry.busy else { return }
    entry.busy = true
    let finish = {
      if self.videoOutputs[handle] === entry {
        self.videoOutputs.removeValue(forKey: handle)
      }
      let completions = entry.destroyCompletions
      entry.destroyCompletions.removeAll()
      completions.forEach { $0() }
    }
    if let output = entry.output {
      entry.output = nil
      output.dispose(completion: finish)
    } else {
      finish()
    }
  }
}
