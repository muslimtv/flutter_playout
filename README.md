# AVPlayer for Flutter

[![pub package](https://img.shields.io/pub/v/flutter_playout.svg)](https://pub.dartlang.org/packages/flutter_playout)

Audio & Video player in Flutter. This plugin provides audio/video playback with background audio 
support, text tracks and lock screen controls for both iOS & Android. It also provides player events 
such as onPlay, onPause, onTime etc. See example for more details.

* Video supports **HLS** and **Progressive Steaming** for both iOS & Android with multi-audio support.

* Audio supports playback from URL only.

### Apps Using flutter_playout
See below for example of apps using flutter_playout.

1. MTA International ([iOS](https://apps.apple.com/us/app/mta-international/id942619881) - [Android](https://play.google.com/store/apps/details?id=tv.mta.apps.muslimtv))

Send a pull request to list your app here.

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

## HLS MultiAudio Support

Please see example app on how to implement multi-audio for Android. On iOS multi-audio is 
provided natively by the AVPlayer.

## Text Tracks Support

To display subtitles, pass in an array of `TextTrack` sources to the `Video` widget. You
can select a track by providing `preferredTextLanguage` to the `Video` widget with
a language ISO code for example `en` or `fr`. This setup only applies to Android. For iOS
please embed text tracks in the HLS manifest.

## Analytics

### Akamai Media Analytics
In order to use Akamai Media Analytics, please depend on the latest `MA-experimental` version of the plugin. 
This plugin supports Akamai Media Analytics for the player for both Android and iOS. This
feature is however optional. If you have the license to use Akamai Media Analytics then
follow below steps to enable this feature.

#### Android

You should have access to the Akamai documentation for the analytics library. Please download
version `2.11` (same as the `ExoPlayer` version used in this plugin) of the `ExoPlayerLoader` and 
analytics library and follow instructions on adding them to your project.

#### iOS
For iOS the analytics library is embedded within the plugin so no setup required on the native side.

#### Enable Plugin in Dart
Once done, you can then pass the `akamaiMediaAnalyticsConfigPATH` and `akamaiMediaAnalyticsCustomData` (optional) 
parameters to the `Video` widget to enable Akamai analytics.

```
Video(
  autoPlay: true,
  showControls: widget.showPlayerControls,
  title: "MTA International",
  subtitle: "Reaching The Corners Of The Earth",
  preferredAudioLanguage: "eng",
  isLiveStream: true,
  position: 0,
  url: _url,
  onViewCreated: _onViewCreated,
  desiredState: widget.desiredState,
  akamaiMediaAnalyticsConfigPATH:
      "https://akamai.net/config.xml",
  akamaiMediaAnalyticsCustomData: new AkamaiMediaAnalyticsData()
      .withTitle("MTA International")
      .withEventName("vod-debug")
      .withDeliveryType(DeliveryType.O)
      .withCategory("My Category")
      .withSubCategory("My Sub-Category")
      .withShow("MTA International")
      .withPlayerId("default")
      .withDebugLogging()
      .build(),
)
```