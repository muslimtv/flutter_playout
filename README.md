# flutter_playout

Audio & Video player in Flutter. This plugin provides audio/video playback with background audio 
support and lock screen controls for both iOS & Android. Also provides player events such as onPlay, 
onPause, onTime etc.

* Video only supports **HLS** at the moment for both iOS & Android.

* Audio supports playback from URL only.

#### iOS Example
||||
:---: |:---:| :---:
![screenshot1](sc1.png)|![screenshot4](sc4.png)|![screenshot3](sc3.png)

#### Android Example
|||
:---: |:---:
![screenshot5](sc5.png)|![screenshot6](sc6.png)

## Getting Started

### Android

Uses `ExoPlayer` with `PlatformView` for Video playback and `MediaPlayer` for audio playback.

When using this plugin, please make sure you have included a notification icon 
for your project in `drawable` resource directory named `ic_notification_icon`.
This plugin will use this icon to show lock screen controls for playback.

### iOS

Uses `AVPlayer` with `PlatformView` for video playback and `AVPlayer` with Flutter 
`MethodChannel`s for audio playback.

Please make sure you've enabled background audio capability for your project.
Please also note that the player might not function properly on a simulator.

Opt-in to the embedded views preview by adding a boolean property to the app's 
**Info.plist** file with the key `io.flutter.embedded_views_preview` and the value `YES`.
