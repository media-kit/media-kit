/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2024 & onwards, cillyvms <cillyvms@estrogen.dev>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:ffi';
import 'dart:io';

typedef MmapFunctionNative = Pointer<Void> Function(Pointer<Void> address, Size length, Int32 protection, Int32 flags, Int32 fd, Long offset);
typedef MmapFunction = Pointer<Void> Function(Pointer<Void> address, int length, int protection, int flags, int fd, int offset);

typedef MunmapFunctionNative = Int32 Function(Pointer<Void> address, Size length);
typedef MunmapFunction = int Function(Pointer<Void> address, int length);

// Constants sourced from Linux kernel headers
const PROT_READ = 0x1;
const PROT_WRITE = 0x2;
const PROT_EXEC = 0x4;

const MAP_FAILED = -1;
const MAP_PRIVATE = 0x2;
const MAP_ANONYMOUS = 0x20;

/// Checks if creating new anonymous executable memory mappings is blocked by the system.
/// Only applies to Linux-based systems, since Dart doesn't use them for NativeCallbacks
/// on Fuchsia and Apple systems.
bool _checkIfExecmemRestricted() {
    if (Platform.isLinux || Platform.isAndroid) {
        try {
            var libs = DynamicLibrary.process();
            var mmap = libs.lookupFunction<MmapFunctionNative, MmapFunction>("mmap", isLeaf: true);
            var munmap = libs.lookupFunction<MunmapFunctionNative, MunmapFunction>("munmap", isLeaf: true);

            var mapping = mmap(nullptr, 4096, PROT_READ | PROT_EXEC, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
            if (mapping.address == MAP_FAILED) {
                // mapping failed, most likely because of execmem restrictions
                return true;
            }
            munmap(mapping, 4096);
        } catch(_) {}
    }
    return false;
}

final isExecmemRestricted = _checkIfExecmemRestricted();
