# [package:media_kit](https://github.com/alexmercerind/media_kit)

A complete video & audio playback library for Flutter & Dart. Performant, stable, feature-proof & modular.

[![](https://img.shields.io/discord/1079685977523617792?color=33cd57&label=Discord&logo=discord&logoColor=discord)](https://discord.gg/h7qf2R9n57) [![Github Actions](https://github.com/alexmercerind/media_kit/actions/workflows/ci.yml/badge.svg)](https://github.com/alexmercerind/media_kit/actions/workflows/ci.yml)

<hr>

<strong>Sponsored with 💖 by</strong>

<a href="https://getstream.io/chat/sdk/flutter/?utm_source=alexmercerind_dart&utm_medium=Github_Repo_Content_Ad&utm_content=Developer&utm_campaign=alexmercerind_December2022_FlutterSDK_klmh22" target="_blank">
  <img alt="Stream Chat" width="300" height="auto" src="https://user-images.githubusercontent.com/28951144/204903022-bbaa49ca-74c2-4a8f-a05d-af8314bfd2cc.svg">
</a>
<br></br>
<strong>
  <a href="https://getstream.io/chat/sdk/flutter/?utm_source=alexmercerind_dart&utm_medium=Github_Repo_Content_Ad&utm_content=Developer&utm_campaign=alexmercerind_December2022_FlutterSDK_klmh22" target="_blank">
  Try the Flutter Chat tutorial
  </a>
</strong>

<br></br>

<a href="https://ottomatic.io/" target="_blank">
  <img alt="Stream Chat" width="300" height="auto" src="https://user-images.githubusercontent.com/28951144/228648844-f2a59ab1-12cd-4fee-bc8d-b2d332033c45.svg">
</a>
<br></br>
<strong>
  <a href="https://ottomatic.io/" target="_blank">
  Clever Apps for Film Professionals
  </a>
</strong>

## Installation

[package:media_kit](https://github.com/alexmercerind/media_kit) is split into number of packages to improve modularity & reduce bundle size.

#### For apps that need video playback:

```yaml
dependencies:
  media_kit: ^0.0.5                              # Primary package.
  
  media_kit_video: ^0.0.7                        # For video rendering.
  
  media_kit_native_event_loop: ^1.0.3            # Support for higher number of concurrent instances & better performance.
  
  media_kit_libs_windows_video: ^1.0.2           # Windows package for video native libraries.
  media_kit_libs_android_video: ^1.0.0           # Android package for video native libraries.
  media_kit_libs_macos_video: ^1.0.4             # macOS package for video native libraries.
  media_kit_libs_ios_video: ^1.0.4               # iOS package for video native libraries.
  media_kit_libs_linux: ^1.0.2                   # GNU/Linux dependency package.
```

#### For apps that need audio playback:

```yaml
dependencies:
  media_kit: ^0.0.5                              # Primary package.
  
  media_kit_native_event_loop: ^1.0.2            # Support for higher number of concurrent instances & better performance.
  
  media_kit_libs_windows_audio: ^1.0.3           # Windows package for audio native libraries.
  media_kit_libs_android_audio: ^1.0.0           # Android package for audio native libraries.
  media_kit_libs_macos_audio: ^1.0.4             # macOS package for audio native libraries.
  media_kit_libs_ios_audio: ^1.0.4               # iOS package for audio native libraries.
  media_kit_libs_linux: ^1.0.2                   # GNU/Linux dependency package.
```

**Notes:**

- If app needs both video & audio playback, select video playback libraries.
- media_kit_libs_*** packages may be omitted depending upon the platform your app targets. 

## Platforms

| Platform | Video | Audio | Notes | Demo |
| -------- | ----- | ----- | ----- | ---- |
| Android     | ✅    | ✅    | Android 5.0 or above.              | [Download](https://github.com/alexmercerind/media_kit/releases/download/media_kit-v0.0.5/media_kit_test_android-arm64-v8a.apk) |
| iOS         | ✅    | ✅    | iOS 13 or above.                   | [Download](https://github.com/alexmercerind/media_kit/releases/download/media_kit-v0.0.5/media_kit_test_ios_arm64.7z)          |
| macOS       | ✅    | ✅    | macOS 11 or above.                 | [Download](https://github.com/alexmercerind/media_kit/releases/download/media_kit-v0.0.5/media_kit_test_macos_universal.7z)    |
| Windows     | ✅    | ✅    | Windows 7 or above.                | [Download](https://github.com/alexmercerind/media_kit/releases/download/media_kit-v0.0.5/media_kit_test_win32_x64.7z)          |
| GNU/Linux   | ✅    | ✅    | Any modern GNU/Linux distribution. | [Download](https://github.com/alexmercerind/media_kit/releases/download/media_kit-v0.0.5/media_kit_test_linux_x64.7z)          |
| Web         | 🚧    | 🚧    | [WIP](https://github.com/alexmercerind/media_kit/pull/128)                                | [WIP](https://github.com/alexmercerind/media_kit/pull/128)              |

<table>
  <tr>
    <td>
      Android
    </td>
    <td>
      iOS
    </td>
  </tr>
  <tr>
    <td>
      <img src="https://user-images.githubusercontent.com/28951144/232696332-37d54a33-9f8b-44df-a564-3420c74eb4da.jpg" height="400" alt="Android"></img>
    </td>
    <td>
      <img src="https://user-images.githubusercontent.com/28951144/232696349-6bad4f2b-439b-43bb-9ced-e05cd52b1477.jpg" height="400" alt="iOS"></img>
    </td>
</table>

<table>
  <tr>
    <td>
      macOS
    </td>
    <td>
      Windows
    </td>
    <td>
      GNU/Linux
    </td>
  </tr>
  <tr>
    <td>
      <img src="https://user-images.githubusercontent.com/28951144/232696378-5c8f76a6-d0a5-4215-8c4f-5a76957e5692.jpg" height="140" width="248.8" alt="macOS"></img>
    </td>
    <td>
      <img src="https://user-images.githubusercontent.com/28951144/232696391-c2577912-21c7-4a63-ad7c-37ded5cb2973.jpg" height="140" width="248.8" alt="Windows"></img>
    </td>
    <td>
      <img src="https://user-images.githubusercontent.com/28951144/232696361-57fa500a-1c24-4e5e-9152-a03bd5b7cfa6.jpg" height="140" width="248.8" alt="GNU/Linux"></img>
    </td>
</table>

## Guide

### TL;DR

A quick usage tutorial.

~~For detailed overview & guide to number of features in the library, please visit the [documentation](#).~~ WIP

#### 1. Initialize the library

```dart
import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const MyApp());
}
```

#### 2. Create a player to play & control an video/audio source with it

```dart
import 'package:media_kit/media_kit.dart';

/// Create a [Player] instance for video or audio playback.

final Player player = Player();

/// Subscribe to event streams & listen to updates.

player.streams.playlist.listen((e) => print(e));
player.streams.playing.listen((e) => print(e));
player.streams.completed.listen((e) => print(e));
player.streams.position.listen((e) => print(e));
player.streams.duration.listen((e) => print(e));
player.streams.volume.listen((e) => print(e));
player.streams.rate.listen((e) => print(e));
player.streams.pitch.listen((e) => print(e));
player.streams.buffering.listen((e) => print(e));

/// Open a playable [Media] or [Playlist].

await player.open(Media('file:///C:/Users/Hitesh/Music/Sample.mp3'));
await player.open(Media('file:///C:/Users/Hitesh/Video/Sample.mkv'));
await player.open(Media('rtsp://www.example.com/live'));
await player.open(Media('asset:///videos/bee.mp4'));
await player.open(
  Playlist(
    [
      Media('https://user-images.githubusercontent.com/28951144/229373695-22f88f13-d18f-4288-9bf1-c3e078d83722.mp4'),
      Media('https://user-images.githubusercontent.com/28951144/229373709-603a7a89-2105-4e1b-a5a5-a6c3567c9a59.mp4'),
      Media('https://user-images.githubusercontent.com/28951144/229373716-76da0a4e-225a-44e4-9ee7-3e9006dbc3e3.mp4'),
      Media('https://user-images.githubusercontent.com/28951144/229373718-86ce5e1d-d195-45d5-baa6-ef94041d0b90.mp4'),
      Media('https://user-images.githubusercontent.com/28951144/229373720-14d69157-1a56-4a78-a2f4-d7a134d7c3e9.mp4'),
    ],
  ),
);

/// Control playback state.

await player.play();
await player.pause();
await player.playOrPause();
await player.seek(const Duration(seconds: 10));

/// Use or modify the queue.

await player.next();
await player.previous();
await player.jump(2);
await player.add(Media('https://www.example.com/sample.mp4'));
await player.move(0, 2);

/// Customize speed, pitch, volume, shuffle, playlist mode, audio device.

await player.setRate(1.0);
await player.setPitch(1.2);
await player.setVolume(50.0);
await player.setShuffle(false);
await player.setPlaylistMode(PlaylistMode.loop);
await player.setAudioDevice(AudioDevice.auto());

/// Release allocated resources back to the system.

await player.dispose();
```

#### 3. Render video output

GPU powered (hardware accelerated), automatically fallbacks to S/W rendering based on system.

```dart
import 'package:flutter/material.dart';

import 'package:media_kit/media_kit.dart';                        /// Provides [Player], [Media], [Playlist] etc.
import 'package:media_kit_video/media_kit_video.dart';            /// Provides [VideoController] & [Video] etc.

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(
    const MaterialApp(
      home: MyScreen()
    ),
  );
}

class MyScreen extends StatefulWidget {
  const MyScreen({Key? key}) : super(key: key);
  @override
  State<MyScreen> createState() => MyScreenState();
}

class MyScreenState extends State<MyScreen> {
  /// Create a [Player].
  final Player player = Player();
  /// Store reference to the [VideoController].
  VideoController? controller;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      /// Create a [VideoController] to show video output of the [Player].
      controller = await VideoController.create(player);
      /// Play any media source.
      await player.open(Media('https://user-images.githubusercontent.com/28951144/229373695-22f88f13-d18f-4288-9bf1-c3e078d83722.mp4'));
      setState(() {});
    });
  }

  @override
  void dispose() {
    Future.microtask(() async {
      /// Release allocated resources back to the system.
      await controller?.dispose();
      await player.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Use [Video] widget to display the output.
    return Video(
      /// Pass the [controller].
      controller: controller,
    );
  }
}
```

## Goals

[package:media_kit](https://github.com/alexmercerind/media_kit) is a library for Flutter & Dart which **provides video & audio playback**.

- **Strong:** Supports _most_ video & audio codecs.
- **Performant:**
  - Handles multiple FHD videos flawlessly.
  - Rendering is GPU powered (hardware accelerated).
  - 4K / 8K 60 FPS is supported.
- **Stable:** Implementation is well tested & used across number of intensive media playback related apps.
- **Feature Proof:** A simple usage API while offering large number of features to target multitude of apps.
- **Modular:** Project is split into number of packages for reducing bundle size.
- **Cross Platform**: Implementation works on all platforms supported by Flutter & Dart:
  - Android
  - iOS
  - macOS
  - Windows
  - GNU/Linux
  - ~~Web~~ WIP
- **Flexible Architecture:**
  - Major part of implementation (80%+) is in 100% Dart ([FFI](https://dart.dev/guides/libraries/c-interop)) & shared across platforms.
    - Makes behavior of library same & more predictable across platforms.
    - Makes development & implementation of new features easier & faster.
    - Avoids separate maintenance of native implementation for each platform.
  - Only video embedding code is platform specific & part of separate package.

You may see project's [architecture](https://github.com/alexmercerind/media_kit#architecture) & [implementation](https://github.com/alexmercerind/media_kit#implementation) details for further information.

The project aims to meet demands of the community, this includes:
1. Holding accountability.
2. Ensuring timely maintenance.

## Fund Development

If you find [package:media_kit](https://github.com/alexmercerind/media_kit) package(s) useful, please consider sponsoring me.

Since this is first of a kind project, it takes a lot of time to experiment & develop. It's a very tedious process to write code, document, maintain & provide support for free. Your support can ensure the quality of the package your project depends upon. I will feel rewarded for my hard-work & research.

- **[GitHub Sponsors](https://github.com/sponsors/alexmercerind)**
- **[PayPal](https://paypal.me/alexmercerind)**

<a href='https://github.com/sponsors/alexmercerind'><img src='https://github.githubassets.com/images/modules/site/sponsors/sponsors-mona.svg' width='240'></a>

Thanks!

## Supported Formats

A wide variety of formats & codecs are supported. Complete list may be found below:

<details>

```
3dostr          3DO STR
4xm             4X Technologies
aa              Audible AA format files
aac             raw ADTS AAC (Advanced Audio Coding)
aax             CRI AAX
ac3             raw AC-3
ace             tri-Ace Audio Container
acm             Interplay ACM
act             ACT Voice file format
adf             Artworx Data Format
adp             ADP
ads             Sony PS2 ADS
adx             CRI ADX
aea             MD STUDIO audio
afc             AFC
aiff            Audio IFF
aix             CRI AIX
alaw            PCM A-law
alias_pix       Alias/Wavefront PIX image
alp             LEGO Racers ALP
amr             3GPP AMR
amrnb           raw AMR-NB
amrwb           raw AMR-WB
anm             Deluxe Paint Animation
apac            raw APAC
apc             CRYO APC
ape             Monkey's Audio
apm             Ubisoft Rayman 2 APM
apng            Animated Portable Network Graphics
aptx            raw aptX
aptx_hd         raw aptX HD
aqtitle         AQTitle subtitles
argo_asf        Argonaut Games ASF
argo_brp        Argonaut Games BRP
argo_cvg        Argonaut Games CVG
asf             ASF (Advanced / Active Streaming Format)
asf_o           ASF (Advanced / Active Streaming Format)
ass             SSA (SubStation Alpha) subtitle
ast             AST (Audio Stream)
au              Sun AU
av1             AV1 Annex B
avi             AVI (Audio Video Interleaved)
avr             AVR (Audio Visual Research)
avs             Argonaut Games Creature Shock
avs2            raw AVS2-P2/IEEE1857.4
avs3            raw AVS3-P2/IEEE1857.10
bethsoftvid     Bethesda Softworks VID
bfi             Brute Force & Ignorance
bfstm           BFSTM (Binary Cafe Stream)
bin             Binary text
bink            Bink
binka           Bink Audio
bit             G.729 BIT file format
bitpacked       Bitpacked
bmp_pipe        piped bmp sequence
bmv             Discworld II BMV
boa             Black Ops Audio
bonk            raw Bonk
brender_pix     BRender PIX image
brstm           BRSTM (Binary Revolution Stream)
c93             Interplay C93
caf             Apple CAF (Core Audio Format)
cavsvideo       raw Chinese AVS (Audio Video Standard)
cdg             CD Graphics
cdxl            Commodore CDXL video
cine            Phantom Cine
codec2          codec2 .c2 demuxer
codec2raw       raw codec2 demuxer
concat          Virtual concatenation script
cri_pipe        piped cri sequence
dash            Dynamic Adaptive Streaming over HTTP
data            raw data
daud            D-Cinema audio
dcstr           Sega DC STR
dds_pipe        piped dds sequence
derf            Xilam DERF
dfa             Chronomaster DFA
dfpwm           raw DFPWM1a
dhav            Video DAV
dirac           raw Dirac
dnxhd           raw DNxHD (SMPTE VC-3)
dpx_pipe        piped dpx sequence
dsf             DSD Stream File (DSF)
dshow           DirectShow capture
dsicin          Delphine Software International CIN
dss             Digital Speech Standard (DSS)
dts             raw DTS
dtshd           raw DTS-HD
dv              DV (Digital Video)
dvbsub          raw dvbsub
dvbtxt          dvbtxt
dxa             DXA
ea              Electronic Arts Multimedia
ea_cdata        Electronic Arts cdata
eac3            raw E-AC-3
epaf            Ensoniq Paris Audio File
exr_pipe        piped exr sequence
f32be           PCM 32-bit floating-point big-endian
f32le           PCM 32-bit floating-point little-endian
f64be           PCM 64-bit floating-point big-endian
f64le           PCM 64-bit floating-point little-endian
ffmetadata      FFmpeg metadata in text
film_cpk        Sega FILM / CPK
filmstrip       Adobe Filmstrip
fits            Flexible Image Transport System
flac            raw FLAC
flic            FLI/FLC/FLX animation
flv             FLV (Flash Video)
frm             Megalux Frame
fsb             FMOD Sample Bank
fwse            Capcom's MT Framework sound
g722            raw G.722
g723_1          G.723.1
g726            raw big-endian G.726 ("left aligned")
g726le          raw little-endian G.726 ("right aligned")
g729            G.729 raw format demuxer
gdigrab         GDI API Windows frame grabber
gdv             Gremlin Digital Video
gem_pipe        piped gem sequence
genh            GENeric Header
gif             CompuServe Graphics Interchange Format (GIF)
gif_pipe        piped gif sequence
gsm             raw GSM
gxf             GXF (General eXchange Format)
h261            raw H.261
h263            raw H.263
h264            raw H.264 video
hca             CRI HCA
hcom            Macintosh HCOM
hdr_pipe        piped hdr sequence
hevc            raw HEVC video
hls             Apple HTTP Live Streaming
hnm             Cryo HNM v4
ico             Microsoft Windows ICO
idcin           id Cinematic
idf             iCE Draw File
iff             IFF (Interchange File Format)
ifv             IFV CCTV DVR
ilbc            iLBC storage
image2          image2 sequence
image2pipe      piped image2 sequence
imf             IMF (Interoperable Master Format)
ingenient       raw Ingenient MJPEG
ipmovie         Interplay MVE
ipu             raw IPU Video
ircam           Berkeley/IRCAM/CARL Sound Format
iss             Funcom ISS
iv8             IndigoVision 8000 video
ivf             On2 IVF
ivr             IVR (Internet Video Recording)
j2k_pipe        piped j2k sequence
jacosub         JACOsub subtitle format
jpeg_pipe       piped jpeg sequence
jpegls_pipe     piped jpegls sequence
jpegxl_pipe     piped jpegxl sequence
jv              Bitmap Brothers JV
kux             KUX (YouKu)
kvag            Simon & Schuster Interactive VAG
laf             LAF (Limitless Audio Format)
lavfi           Libavfilter virtual input device
live_flv        live RTMP FLV (Flash Video)
lmlm4           raw lmlm4
loas            LOAS AudioSyncStream
lrc             LRC lyrics
luodat          Video CCTV DAT
lvf             LVF
lxf             VR native stream (LXF)
m4v             raw MPEG-4 video
matroska,webm   Matroska / WebM
mca             MCA Audio Format
mcc             MacCaption
mgsts           Metal Gear Solid: The Twin Snakes
microdvd        MicroDVD subtitle format
mjpeg           raw MJPEG video
mjpeg_2000      raw MJPEG 2000 video
mlp             raw MLP
mlv             Magic Lantern Video (MLV)
mm              American Laser Games MM
mmf             Yamaha SMAF
mods            MobiClip MODS
moflex          MobiClip MOFLEX
mov,mp4,m4a,3gp,3g2,mj2 QuickTime / MOV
mp3             MP2/3 (MPEG audio layer 2/3)
mpc             Musepack
mpc8            Musepack SV8
mpeg            MPEG-PS (MPEG-2 Program Stream)
mpegts          MPEG-TS (MPEG-2 Transport Stream)
mpegtsraw       raw MPEG-TS (MPEG-2 Transport Stream)
mpegvideo       raw MPEG video
mpjpeg          MIME multipart JPEG
mpl2            MPL2 subtitles
mpsub           MPlayer subtitles
msf             Sony PS3 MSF
msnwctcp        MSN TCP Webcam stream
msp             Microsoft Paint (MSP))
mtaf            Konami PS2 MTAF
mtv             MTV
mulaw           PCM mu-law
musx            Eurocom MUSX
mv              Silicon Graphics Movie
mvi             Motion Pixels MVI
mxf             MXF (Material eXchange Format)
mxg             MxPEG clip
nc              NC camera feed
nistsphere      NIST SPeech HEader REsources
nsp             Computerized Speech Lab NSP
nsv             Nullsoft Streaming Video
nut             NUT
nuv             NuppelVideo
obu             AV1 low overhead OBU
ogg             Ogg
oma             Sony OpenMG audio
paf             Amazing Studio Packed Animation File
pam_pipe        piped pam sequence
pbm_pipe        piped pbm sequence
pcx_pipe        piped pcx sequence
pfm_pipe        piped pfm sequence
pgm_pipe        piped pgm sequence
pgmyuv_pipe     piped pgmyuv sequence
pgx_pipe        piped pgx sequence
phm_pipe        piped phm sequence
photocd_pipe    piped photocd sequence
pictor_pipe     piped pictor sequence
pjs             PJS (Phoenix Japanimation Society) subtitles
pmp             Playstation Portable PMP
png_pipe        piped png sequence
pp_bnk          Pro Pinball Series Soundbank
ppm_pipe        piped ppm sequence
psd_pipe        piped psd sequence
psxstr          Sony Playstation STR
pva             TechnoTrend PVA
pvf             PVF (Portable Voice Format)
qcp             QCP
qdraw_pipe      piped qdraw sequence
qoi_pipe        piped qoi sequence
r3d             REDCODE R3D
rawvideo        raw video
realtext        RealText subtitle format
redspark        RedSpark
rka             RKA (RK Audio)
rl2             RL2
rm              RealMedia
roq             id RoQ
rpl             RPL / ARMovie
rsd             GameCube RSD
rso             Lego Mindstorms RSO
rtp             RTP input
rtsp            RTSP input
s16be           PCM signed 16-bit big-endian
s16le           PCM signed 16-bit little-endian
s24be           PCM signed 24-bit big-endian
s24le           PCM signed 24-bit little-endian
s32be           PCM signed 32-bit big-endian
s32le           PCM signed 32-bit little-endian
s337m           SMPTE 337M
s8              PCM signed 8-bit
sami            SAMI subtitle format
sap             SAP input
sbc             raw SBC (low-complexity subband codec)
sbg             SBaGen binaural beats script
scc             Scenarist Closed Captions
scd             Square Enix SCD
sdns            Xbox SDNS
sdp             SDP
sdr2            SDR2
sds             MIDI Sample Dump Standard
sdx             Sample Dump eXchange
ser             SER (Simple uncompressed video format for astronomical capturing)
sga             Digital Pictures SGA
sgi_pipe        piped sgi sequence
shn             raw Shorten
siff            Beam Software SIFF
simbiosis_imx   Simbiosis Interactive IMX
sln             Asterisk raw pcm
smjpeg          Loki SDL MJPEG
smk             Smacker
smush           LucasArts Smush
sol             Sierra SOL
sox             SoX native
spdif           IEC 61937 (compressed data in S/PDIF)
srt             SubRip subtitle
stl             Spruce subtitle format
subviewer       SubViewer subtitle format
subviewer1      SubViewer v1 subtitle format
sunrast_pipe    piped sunrast sequence
sup             raw HDMV Presentation Graphic Stream subtitles
svag            Konami PS2 SVAG
svg_pipe        piped svg sequence
svs             Square SVS
swf             SWF (ShockWave Flash)
tak             raw TAK
tedcaptions     TED Talks captions
thp             THP
tiertexseq      Tiertex Limited SEQ
tiff_pipe       piped tiff sequence
tmv             8088flex TMV
truehd          raw TrueHD
tta             TTA (True Audio)
tty             Tele-typewriter
txd             Renderware TeXture Dictionary
ty              TiVo TY Stream
u16be           PCM unsigned 16-bit big-endian
u16le           PCM unsigned 16-bit little-endian
u24be           PCM unsigned 24-bit big-endian
u24le           PCM unsigned 24-bit little-endian
u32be           PCM unsigned 32-bit big-endian
u32le           PCM unsigned 32-bit little-endian
u8              PCM unsigned 8-bit
v210            Uncompressed 4:2:2 10-bit
v210x           Uncompressed 4:2:2 10-bit
vag             Sony PS2 VAG
vbn_pipe        piped vbn sequence
vc1             raw VC-1
vc1test         VC-1 test bitstream
vfwcap          VfW video capture
vidc            PCM Archimedes VIDC
vividas         Vividas VIV
vivo            Vivo
vmd             Sierra VMD
vobsub          VobSub subtitle format
voc             Creative Voice
vpk             Sony PS2 VPK
vplayer         VPlayer subtitles
vqf             Nippon Telegraph and Telephone Corporation (NTT) TwinVQ
w64             Sony Wave64
wady            Marble WADY
wav             WAV / WAVE (Waveform Audio)
wavarc          Waveform Archiver
wc3movie        Wing Commander III movie
webm_dash_manifest WebM DASH Manifest
webp_pipe       piped webp sequence
webvtt          WebVTT subtitle
wsaud           Westwood Studios audio
wsd             Wideband Single-bit Data (WSD)
wsvqa           Westwood Studios VQA
wtv             Windows Television (WTV)
wv              WavPack
wve             Psion 3 audio
xa              Maxis XA
xbin            eXtended BINary text (XBIN)
xbm_pipe        piped xbm sequence
xmd             Konami XMD
xmv             Microsoft XMV
xpm_pipe        piped xpm sequence
xvag            Sony PS3 XVAG
xwd_pipe        piped xwd sequence
xwma            Microsoft xWMA
yop             Psygnosis YOP
yuv4mpegpipe    YUV4MPEG pipe
```

</details>

**Notes:**
- The list contains the supported formats (& not containers).
  - A video/audio format may be present in a number of containers.
  - e.g. an MP4 file generally contains H264 video stream.

## Notes

### GNU/Linux

System shared libraries from distribution specific user-installed packages are used by-default. You can install these as follows:

#### Ubuntu/Debian

```bash
sudo apt install libmpv-dev mpv
```

#### Packaging

There are other ways to bundle these within your app package e.g. within Snap or Flatpak. Few examples:

- [Celluloid](https://github.com/celluloid-player/celluloid/blob/master/flatpak/io.github.celluloid_player.Celluloid.json)
- [VidCutter](https://github.com/ozmartian/vidcutter/tree/master/\_packaging)

### macOS

During the build phase, the following warnings are not critical and cannot be silenced:

```log
#import "Headers/media_kit_video-Swift.h"
        ^
/path/to/media_kit/media_kit_test/build/macos/Build/Products/Debug/media_kit_video/media_kit_video.framework/Headers/media_kit_video-Swift.h:270:31: warning: 'objc_ownership' only applies to Objective-C object or block pointer types; type here is 'CVPixelBufferRef' (aka 'struct __CVBuffer *')
- (CVPixelBufferRef _Nullable __unsafe_unretained)copyPixelBuffer SWIFT_WARN_UNUSED_RESULT;
```

```log
# 1 "<command line>" 1
 ^
<command line>:20:9: warning: 'POD_CONFIGURATION_DEBUG' macro redefined
#define POD_CONFIGURATION_DEBUG 1 DEBUG=1 
        ^
#define POD_CONFIGURATION_DEBUG 1
        ^
```

## License

Copyright © 2021 & onwards, Hitesh Kumar Saini <<saini123hitesh@gmail.com>>

This project & the work under this repository is governed by MIT license that can be found in the [LICENSE](./LICENSE) file.
