/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2024 & onwards, cillyvms <cillyvms@estrogen.dev>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
// ignore_for_file: constant_identifier_names

import 'dart:ffi';
import 'dart:io';

/// Whether creating new anonymous executable memory mappings is blocked by the system.
final bool isExecmemRestricted = _checkIfExecmemRestricted();

/// Checks if creating new anonymous executable memory mappings is blocked by the system.
/// Only applies to Linux-based systems, since Dart doesn't use them for [NativeCallback]s on Fuchsia and Apple systems.
bool _checkIfExecmemRestricted() {
  if (Platform.isLinux || Platform.isAndroid) {
    try {
      final libs = DynamicLibrary.process();
      final mmap = libs.lookupFunction<MmapFunctionNative, MmapFunctionDart>(
        'mmap',
        isLeaf: true,
      );
      final munmap =
          libs.lookupFunction<MunmapFunctionNative, MunmapFunctionDart>(
        'munmap',
        isLeaf: true,
      );
      final mapping = mmap(
        nullptr,
        4096,
        PROT_READ | PROT_EXEC,
        MAP_PRIVATE | MAP_ANONYMOUS,
        -1,
        0,
      );
      if (mapping.address == MAP_FAILED) {
        // Mapping failed, most likely because of execmem restrictions.
        return true;
      }
      munmap(mapping, 4096);
    } catch (_) {}
  }
  return false;
}

// Constants sourced from Linux kernel headers.

const PROT_READ = 0x1;
const PROT_WRITE = 0x2;
const PROT_EXEC = 0x4;

const MAP_FAILED = -1;
const MAP_PRIVATE = 0x2;
const MAP_ANONYMOUS = 0x20;

typedef MmapFunctionNative = Pointer<Void> Function(
    Pointer<Void>, Size, Int32, Int32, Int32, Long);
typedef MmapFunctionDart = Pointer<Void> Function(
    Pointer<Void>, int, int, int, int, int);

typedef MunmapFunctionNative = Int32 Function(Pointer<Void>, Size);
typedef MunmapFunctionDart = int Function(Pointer<Void>, int);
