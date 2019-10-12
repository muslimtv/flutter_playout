import 'package:flutter/services.dart';

/// See [play] method as well as example app on how to use.
class Audio {
  MethodChannel _audioChannel;

  Audio() {
    _audioChannel = const MethodChannel('tv.mta/NativeAudioChannel');
  }

  /// Plays given [url] with native player. The [title] and [subtitle]
  /// are used for lock screen info panel on both iOS & Android. Optionally pass
  /// in current [position] to start playback from that point. The
  /// [isLiveStream] flag is only used on iOS to change the scrub-bar look
  /// on lock screen info panel. It has no affect on the actual functionality
  /// of the plugin. Defaults to false.
  Future<void> play(String url,
      {String title = "",
      String subtitle = "",
      Duration position = Duration.zero,
      bool isLiveStream = false}) async {
    await _audioChannel.invokeMethod("play", <String, dynamic>{
      "url": url,
      "title": title,
      "subtitle": subtitle,
      "position": position.inMilliseconds,
      "isLiveStream": isLiveStream,
    });
  }

  Future<void> pause() async {
    await _audioChannel.invokeMethod("pause");
  }

  Future<void> stop() async {
    await _audioChannel.invokeMethod("stop");
  }

  Future<void> seekTo(double seconds) async {
    await _audioChannel.invokeMethod("seekTo", <String, dynamic>{
      "second": seconds,
    });
  }

  Future<void> dispose() async {
    await stop();
  }
}
