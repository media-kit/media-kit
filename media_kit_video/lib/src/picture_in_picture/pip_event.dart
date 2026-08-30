/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

/// Base class for events emitted by [PictureInPictureController.events].
///
/// Subclasses represent discrete lifecycle transitions and playback control
/// callbacks forwarded by the host platform.
abstract class PipEvent {
  const PipEvent();
}

/// Emitted when the system is about to enter Picture-in-Picture.
class PipWillStart extends PipEvent {
  const PipWillStart();
}

/// Emitted when Picture-in-Picture has entered.
class PipDidStart extends PipEvent {
  const PipDidStart();
}

/// Emitted when the system is about to exit Picture-in-Picture.
class PipWillStop extends PipEvent {
  const PipWillStop();
}

/// Emitted when Picture-in-Picture exited and the host interface was
/// restored (user tapped the "go back" affordance on iOS).
class PipDidStop extends PipEvent {
  const PipDidStop();
}

/// Emitted when the user requests the host interface to be restored while
/// Picture-in-Picture is active.
class PipRestore extends PipEvent {
  const PipRestore();
}

/// Emitted when Picture-in-Picture was closed without restoring the host
/// interface (user tapped the close button on the floating window).
class PipClosed extends PipEvent {
  const PipClosed();
}

/// Emitted when Picture-in-Picture failed to start or could not be resumed.
class PipFailed extends PipEvent {
  const PipFailed(this.reason);

  final String reason;
}

/// Emitted when the Picture-in-Picture controls request a playback state
/// change (play / pause).
class PipSetPlaying extends PipEvent {
  const PipSetPlaying({required this.playing});

  final bool playing;
}
