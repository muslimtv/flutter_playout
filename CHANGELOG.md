## 2.0.1 [June 12, 2021]

* Set iOS deployment target to 9.0
* Fixed observed value unhandled exception in iOS implementation

## 2.0.0 [June 11, 2021]

* Migrated to null-safety

## 1.0.43 [June 8, 2021]

* Updated iOS deployment target to 9.0

## 1.0.42 [November 10, 2020]

* Merged [PR](https://github.com/muslimtv/flutter_playout/pull/70)

## 1.0.41 [September 13, 2020]

* removed isEmpty check when setting text track language

## 1.0.40 [September 7, 2020]

* added support for text tracks for Android
* added text track change listener to player

## 1.0.39 [September 7, 2020]

* Added support for text tracks for Android

## 1.0.38 [August 25, 2020]

* Merged [PR](https://github.com/muslimtv/flutter_playout/pull/61)
* fixes [#60](https://github.com/muslimtv/flutter_playout/issues/60)

## 1.0.37 [August 4, 2020]

* moved Akamai Media Analytics plugin to a separate branch

## 1.0.36 [July 29, 2020]

* implemented Akamai Media Analytics

## 1.0.35 [April 18, 2020]

* Merged PR [#41](https://github.com/muslimtv/flutter_playout/pull/41)

## 1.0.34 [April 10, 2020]

* fixes [#39](https://github.com/muslimtv/flutter_playout/issues/39)

## 1.0.33 [March 23, 2020]

* Merged PR (https://github.com/muslimtv/flutter_playout/pull/29)

## 1.0.32 [March 23, 2020]

* Merged PR (https://github.com/muslimtv/flutter_playout/pull/28)

* Fixed wrong arguments casting in Android PlayerLayout. It was throwing exception and the change wouldn't happen.

* Fixed crash on iOS when attempting to change media. It was crashing due to force unwrapping a non existing value (showControls).

## 1.0.31 [March 23, 2020]

* Merged PR to add progressive video source for Android (https://github.com/muslimtv/flutter_playout/pull/26)

## 1.0.30 [February 15, 2020]

* Fixed an issue causing audio player to re-initialize on widget rebuild even though param 
values haven't changed

## 1.0.29 [February 14, 2020]

* Changed [position] from int to double

## 1.0.28 [February 14, 2020]

* Added [position] param for Video set set/update seek bar position

## 1.0.27 [February 14, 2020]

* Added **preferredAudioLanguage** param to Video to set audio language on player init

## 1.0.26 [February 11, 2020]

* Added support for HLS multi-audio for Android

## 1.0.25 [February 7, 2020]

* Fixed a bug where audio service wasn't being destroyed with player
* Fixed an issue where onTime was not being called after audio player is disposed once and recreated

## 1.0.24 [February 7, 2020]

* Updated example to include media change callback

## 1.0.23 [February 7, 2020]

* Fixed an issue where media change (url change) was not being registered with Android audio player

## 1.0.22 [February 7, 2020]

* Fixed an issue where audio player on Android native side was not being disposed properly

## 1.0.21 [February 7, 2020]

* Changed video platform view dispose to use method channel

## 1.0.20 [February 7, 2020]

* Fixed an issue throwing exception at video platform view dispose

## 1.0.19 [January 29, 2020]

* Merged pull request #15 - Ability to show/hide player controls

## 1.0.18 [January 17, 2020]

* Moved player initialisation outside of build() method fixing issue where the underlying platform view keeps rebuilding whenever widget updates.

## 1.0.17 [January 4, 2020]

* Fixed an issue where audioServiceBinder was being used before initialisation

## 1.0.16 [December 10, 2019]

* Fixed an issue where onDuration wasn't being called after player re-init

## 1.0.15 [December 10, 2019]

* Fixed AVPlayer (iOS) reset issue on dispose

## 1.0.14 [December 10, 2019]

* Fixed an issue where Audio instance wasn't being cleared on dispose

## 1.0.13 [December 10, 2019]

* Implemented audio player as singleton

## 1.0.12 [December 10, 2019]

* Fixed an issue where dispose on iOS was failing because it was trying to remove observers twice

## 1.0.11 [October 27, 2019]

* fixed a bug in example app causing audio player to stop sending events after onComplete

* fixed an issue with iOS audio player implementation causing URLs to not play

## 1.0.10 [October 27, 2019]

* fixed an issue causing audio player to crash on malformed URLs

* added better exception handling for audio player

## 1.0.9 [October 26, 2019]

* Implemented `desiredState` flag in Video widget to play/pause video playback.

## 1.0.8 [October 24, 2019]

* fixed an issue where audio player was not playing new media on url change

## 1.0.7 [October 24, 2019]

* Added onDuration callback & updated example to reflect the change
* Implemented onComplete for Android audio player

## 1.0.6 [October 17, 2019]

* Fixed an issue with audio player where onPlay & onPause were not being fired

## 1.0.5 [October 12, 2019]

* Fixed an issue causing iOS plugin to not respond to dispose

## 1.0.4 [October 12, 2019]

* Updated iOS plugin to use Swift 5 compiler

## 1.0.3 [October 12, 2019]

* Implemented video playback for Android
* Fixed an issue with lock screen controls where subtitle wasn't being displayed correctly

## 1.0.2 [October 9, 2019]

* Implemented video playback for iOS

## 1.0.1
* Updated documentation to include example implementation for the plugin

## 1.0.0

* Play audio for both iOS & Android
* Play audio in background with lock screen controls for both iOS & Android