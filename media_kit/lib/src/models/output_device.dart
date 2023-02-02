/// This file is a part of libmpv.dart (https://github.com/alexmercerind/libmpv.dart).
///
/// Copyright (c) 2022, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
/// Domingo Montesdeoca González <DomingoMG97@gmail.com>

/// ## Device
/// A [OutputDevice] object to open inside a [Player] instance using [Player.setOutputDevice] method for playback.
///
/// ```dart
/// /// [Player] instance 
/// Player player = Player();
/// 
/// /// Get list of output devices to the [Player]
/// List<Device> devices = player.getOutputDevices();
/// 
/// /// Assign the output device to the [Player].
/// player.setOutputDevice = devices[index];
/// 
/// 
/// ```
///
class OutputDevice {
  /// [OutputDevice] name.
  final String name;
  
  /// [OutputDevice] description.
  final String description;

  OutputDevice(
    this.name,
    this.description
  );

  factory OutputDevice.fromMap( Map<String, dynamic> map ) => OutputDevice(
    map['name'], 
    map['description']
  );

  @override
  bool operator ==(Object other) {
    if (other is OutputDevice) {
      return other.name == name;
    }
    return false;
  }

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'Device($name, description: $description)';
}
