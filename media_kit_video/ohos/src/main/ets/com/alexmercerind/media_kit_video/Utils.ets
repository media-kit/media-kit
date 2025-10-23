/**
 * This file is a part of media_kit (https://github.com/media-kit/media-kit).
 *
 * Copyright © 2025 & onwards, Bao Han <erbws@foxmail.com>.
 * All rights reserved.
 * Use of this source code is governed by MIT license that can be found in the LICENSE file.
 */

import deviceInfo from '@ohos.deviceInfo';

export class Utils {
  static isEmulator(): boolean {
    if (deviceInfo.productModel == "emulator") {
      return true;
    } else {
      return false;
    }
  }
}

export interface Rect {
  left: number,
  top: number,
  width: number,
  height: number,
}

export interface SizeData {
  handle: number,
  id: number,
  wid: number,
  rect: Rect,
}