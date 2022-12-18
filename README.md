# [package:media_kit](https://github.com/alexmercerind/media_kit)

A complete video & audio library for Flutter.

## Goals

The primary goal of [package:media_kit](https://github.com/alexmercerind/media_kit) is to become a strong, stable, feature-proof & modular media playback library for Flutter. The idea is to support both audio & video playback. Besides media playback, a tag-reader is also implemented.

[package:media_kit](https://github.com/alexmercerind/media_kit) makes rendering [hardware accelerated video playback](https://github.com/alexmercerind/dart_vlc/issues/345) possible in Flutter.

Since, targetting multiple features at once & bundling redundant native libraries can result in increased bundle size of the application, you can manually select the native libraries you want to bundle, depending upon your use-case. Currently, the scope of work is limited to Windows & Linux. The code is architectured to support multiple platforms & features. Support for more platforms will be added in future.

## Architecture

Few attributes or details may me not present.

```mermaid
classDiagram
   
  Player *-- PlatformPlayer
  PlatformPlayer <|-- libmpv_Player
  PlatformPlayer <|-- xyz_Player  
  PlatformPlayer *-- PlayerState
  PlatformPlayer *-- PlayerStreams
  PlatformPlayer o-- PlayerConfiguration
  
  libmpv_Player <.. NativeLibrary
  
  class Media {
    +Uri uri
    +dynamic extras
  }
  
  class Playlist {
    +List<Media> medias
    +index index
  }

  class PlayerConfiguration {
    + bool texture
    + bool osc
    + String vo
    + String title
    ... other platform-specific configurable values
  }
  
  class PlayerStreams {
    +Stream<Playlist> playlist
    +Stream<bool> isPlaying
    +Stream<bool> isCompleted
    +Stream<Duration> position
    +Stream<Duration> duration
    +Stream<double> volume
    +Stream<double> rate
    +Stream<double> pitch
    +Stream<bool> isBuffering
    +Stream<AudioParams> audioParams
    +Stream<double> audioBitrate
    +Stream<PlayerError> error
  }
  
  class PlayerState {
    +Playlist playlist
    +bool isPlaying
    +bool isCompleted
    +Duration position
    +Duration duration
    +double volume
    +double rate
    +double pitch
    +bool isBuffering
    +AudioParams audioParams
    +double audioBitrate
    +PlayerError error
  }
  
  class Player {
    +PlatformPlayer? platform
    
    +«get» PlayerState state
    +«get» PlayerStreams streams
    
    +«set» volume: double*
    +«set» rate: double*
    +«set» pitch: double*
    +«set» shuffle: bool*
    
    +open(playlist)*
    +play()*
    +pause()*
    +playOrPause()*
    +add(media)*
    +remove(index)*
    +next()*
    +previous()*
    +jump(index)*
    +move(from, to)*
    +seek(duration)*
    +setPlaylistMode(playlistMode)*
    +dispose()*
  }
  
  class PlatformPlayer {
    +PlayerState state
    +PlayerStreams streams
    +PlayerConfiguration configuration
    
    +open(playlist)*
    +play()*
    +pause()*
    +playOrPause()*
    +add(media)*
    +remove(index)*
    +next()*
    +previous()*
    +jump(index)*
    +move(from, to)*
    +seek(duration)*
    +setPlaylistMode(playlistMode)*
    +dispose()*
    
    +«set» volume: double*
    +«set» rate: double*
    +«set» pitch: double*
    +«set» shuffle: bool*
    
    #StreamController<Playlist> playlistController
    #StreamController<bool> isPlayingController
    #StreamController<bool> isCompletedController
    #StreamController<Duration> positionController
    #StreamController<Duration> durationController
    #StreamController<double> volumeController
    #StreamController<double> rateController
    #StreamController<double> pitchController
    #StreamController<bool> isBufferingController
    #StreamController<PlayerError> errorController
    #StreamController<AudioParams> audioParamsController
    #StreamController<double?> audioBitrateController
  }
  
  class libmpv_Player {
    +open(playlist)
    +play()
    +pause()
    +playOrPause()
    +add(media)
    +remove(index)
    +next()
    +previous()
    +jump(index)
    +move(from, to)
    +seek(duration)
    +setPlaylistMode(playlistMode)
    +«set» volume: double
    +«set» rate: double
    +«set» pitch: double
    +«set» shuffle: bool
    +dispose()
  }
  
  class NativeLibrary {
    +find()$ String?
  }
  
  class xyz_Player {
    +open(playlist)
    +play()
    +pause()
    +playOrPause()
    +add(media)
    +remove(index)
    +next()
    +previous()
    +jump(index)
    +move(from, to)
    +seek(duration)
    +setPlaylistMode(playlistMode)
    +«set» volume: double
    +«set» rate: double
    +«set» pitch: double
    +«set» shuffle: bool
    +dispose()
  }
```

```mermaid
classDiagram

  Tagger *-- PlatformTagger
  PlatformTagger <|-- libmpv_Tagger
  PlatformTagger <|-- xyz_Tagger
  PlatformTagger o-- TaggerConfiguration
  
  libmpv_Tagger <.. NativeLibrary
  
  class Media {
    +Uri uri
  }
  
  class TaggerMetadata {
    +Uri uri
    +String trackName
    +String albumName
    +int trackNumber
    +int discNumber
    +int albumLength
    +String albumArtistName
    +List<String> trackArtistNames
    +String authorName
    +String writerName
    +String year
    +String genre
    +String lyrics
    +DateTime timeAdded
    +Duration duration
    +int bitrate
    +dynamic data
  }
  
  class Tagger {
    +parse(media) Future<TaggerMetadata>
    +dispose()
  }
  
  class TaggerConfiguration {
    +bool verbose
    +String libmpv
    ... other platform-specific configurable values
  }
  
  class PlatformTagger {
    +TaggerConfiguration configuration
    
    +parse(media)* Future<TaggerMetadata>
    #serialize(data)* TaggerMetadata
    +dispose()*
    
    #splitArtistTag(tag) List<String>
    #splitDateTag(tag) String
    #parseInteger(value) int
  }
  
  class libmpv_Tagger {
    +parse(media) Future<TaggerMetadata>
    #serialize(data) TaggerMetadata
    +dispose()
  }
  
  class NativeLibrary {
    +find()$ String?
  }
  
  class xyz_Tagger {
    +parse(media) Future<TaggerMetadata>
    #serialize(data) TaggerMetadata
    +dispose()
  }
```
