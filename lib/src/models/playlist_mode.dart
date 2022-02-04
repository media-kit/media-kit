/// This file is a part of libmpv.dart (https://github.com/alexmercerind/libmpv.dart).
///
/// Copyright (c) 2022, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

enum PlaylistMode {
  /// End playback once end of the playlist is reached.
  none,

  /// Indefinitely loop over the currently playing file in the playlist.
  single,

  /// Loop over the playlist & restart it from beginning once end is reached.
  loop,
}
