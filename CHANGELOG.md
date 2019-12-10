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