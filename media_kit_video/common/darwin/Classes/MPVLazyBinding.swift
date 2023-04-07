import Foundation

// Contains dynamically binded libmpv functions useful for this project.
// The names of the methods are identical to libmpv functions when they are
// dynamically linked, in order to be interoperable.
//
// Dev part: to find the signature of the functions, we can "cheat" by putting
// in a `main.swift` file a code example using the libmpv functions and then
// using this command:
//
// ```shell
// $ swiftc \
//     -import-objc-header /path/to/include/mpv/render.h \
//     -emit-sil main.swift 2> main.sil
// ```
//
// Next, just search `main.sil` for definitions starting with `@convention(c)`.
public enum MPVLazyBinding {
  private static let dylib: UnsafeMutableRawPointer = {
    let dylib = dlopen("Mpv.framework/Mpv", RTLD_LAZY)
    if dylib == nil {
      let error = String(cString: dlerror())
      NSLog("dlopen: error: \(error)")
      exit(1)
    }

    return dylib!
  }()

  private static func _dlsym(_ symbol: String) -> UnsafeMutableRawPointer {
    let sym = dlsym(MPVLazyBinding.dylib, symbol)
    if sym == nil {
      let error = String(cString: dlerror())
      NSLog("dlsym: error: \(error)")
      exit(1)
    }

    return sym!
  }

  public static let mpv_error_string: (Int32) -> String = {
    typealias FunctionPrototype = @convention(c) (
      Int32
    ) -> UnsafeMutablePointer<Int8>

    let sym = MPVLazyBinding._dlsym("mpv_error_string")
    let mpv_error_string = unsafeBitCast(sym, to: FunctionPrototype.self)

    return { (_ error: Int32) -> String in
      let result = mpv_error_string(error)
      return String(cString: result)
    }
  }()

  private static let _mpv_get_property: (
    OpaquePointer,
    String,
    mpv_format,
    inout Int64
  ) -> Int32 = {
    typealias FunctionPrototype = @convention(c) (
      OpaquePointer,
      UnsafeMutablePointer<Int8>,
      mpv_format,
      UnsafeMutableRawPointer
    ) -> Int32

    let sym = MPVLazyBinding._dlsym("mpv_get_property")
    let mpv_get_property = unsafeBitCast(sym, to: FunctionPrototype.self)

    return { (
      _ ctx: OpaquePointer,
      _ name: String,
      _ format: mpv_format,
      _ data: inout Int64
    ) -> Int32 in
      mpv_get_property(ctx, strdup(name), format, &data)
    }
  }()

  @discardableResult
  public static func mpv_get_property(
    _ ctx: OpaquePointer,
    _ name: String,
    _ format: mpv_format,
    _ data: inout Int64
  ) -> Int32 {
    return _mpv_get_property(ctx, name, format, &data)
  }

  private static let _mpv_set_option_string: (
    OpaquePointer,
    String,
    String
  ) -> Int32 = {
    typealias FunctionPrototype = @convention(c) (
      OpaquePointer,
      UnsafeMutablePointer<Int8>,
      UnsafeMutablePointer<Int8>
    ) -> Int32

    let sym = MPVLazyBinding._dlsym("mpv_set_option_string")
    let mpv_set_option_string = unsafeBitCast(sym, to: FunctionPrototype.self)

    return { (
      _ ctx: OpaquePointer,
      _ name: String,
      _ data: String
    ) -> Int32 in
      mpv_set_option_string(ctx, strdup(name), strdup(data))
    }
  }()

  @discardableResult
  public static func mpv_set_option_string(
    _ ctx: OpaquePointer,
    _ name: String,
    _ data: String
  ) -> Int32 {
    return _mpv_set_option_string(ctx, name, data)
  }

  private static let _mpv_render_context_create: (
    inout OpaquePointer?,
    OpaquePointer,
    inout [mpv_render_param]
  ) -> Int32 = {
    typealias FunctionPrototype = @convention(c) (
      UnsafeMutablePointer<OpaquePointer?>,
      OpaquePointer,
      UnsafeMutablePointer<mpv_render_param>
    ) -> Int32

    let sym = MPVLazyBinding._dlsym("mpv_render_context_create")
    let mpv_render_context_create =
      unsafeBitCast(sym, to: FunctionPrototype.self)

    return { (
      _ res: inout OpaquePointer?,
      _ mpv: OpaquePointer,
      _ params: inout [mpv_render_param]
    ) -> Int32 in
      mpv_render_context_create(&res, mpv, &params)
    }
  }()

  @discardableResult
  public static func mpv_render_context_create(
    _ res: inout OpaquePointer?,
    _ mpv: OpaquePointer,
    _ params: inout [mpv_render_param]
  ) -> Int32 {
    return _mpv_render_context_create(&res, mpv, &params)
  }

  public static let mpv_render_context_free: (OpaquePointer?) -> Void = {
    typealias FunctionPrototype = @convention(c) (OpaquePointer?) -> Void

    let sym = MPVLazyBinding._dlsym("mpv_render_context_free")
    let mpv_render_context_free = unsafeBitCast(sym, to: FunctionPrototype.self)

    return { (_ ctx: OpaquePointer?) in
      mpv_render_context_free(ctx)
    }
  }()

  private static let _mpv_render_context_render: (
    OpaquePointer?,
    inout [mpv_render_param]
  ) -> Int32 = {
    typealias FunctionPrototype = @convention(c) (
      OpaquePointer?,
      UnsafeMutablePointer<mpv_render_param>
    ) -> Int32

    let sym = MPVLazyBinding._dlsym("mpv_render_context_render")
    let mpv_render_context_render =
      unsafeBitCast(sym, to: FunctionPrototype.self)

    return { (
      _ ctx: OpaquePointer?,
      _ params: inout [mpv_render_param]
    ) -> Int32 in
      mpv_render_context_render(ctx, &params)
    }
  }()

  @discardableResult
  public static func mpv_render_context_render(
    _ ctx: OpaquePointer?,
    _ params: inout [mpv_render_param]
  ) -> Int32 {
    return _mpv_render_context_render(ctx, &params)
  }

  public typealias CallbackPrototype = @convention(c) (
    UnsafeMutableRawPointer?
  ) -> Void

  public static let mpv_render_context_set_update_callback: (
    OpaquePointer?,
    CallbackPrototype?,
    UnsafeMutableRawPointer?
  ) -> Void = {
    typealias FunctionPrototype = @convention(c) (
      OpaquePointer?,
      CallbackPrototype?,
      UnsafeMutableRawPointer?
    ) -> Void

    let sym = MPVLazyBinding._dlsym("mpv_render_context_set_update_callback")
    let mpv_render_context_set_update_callback =
      unsafeBitCast(sym, to: FunctionPrototype.self)

    return { (
      _ ctx: OpaquePointer?,
      _ callback: CallbackPrototype?,
      _ callback_ctx: UnsafeMutableRawPointer?
    ) in
      mpv_render_context_set_update_callback(ctx, callback, callback_ctx)
    }
  }()
}
