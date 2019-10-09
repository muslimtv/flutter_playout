import 'dart:async';

import 'package:flutter/services.dart';

mixin PlayerObserver {
  Future<void> listenForVideoPlayerEvents(int viewId) async {
    EventChannel eventChannel = EventChannel(
        "tv.mta/NativeVideoPlayerEventChannel_$viewId", JSONMethodCodec());
    eventChannel.receiveBroadcastStream().listen(processEvent);
  }

  Future<void> listenForAudioPlayerEvents() async {
    EventChannel eventChannel =
        EventChannel("tv.mta/NativeAudioEventChannel", JSONMethodCodec());
    eventChannel.receiveBroadcastStream().listen(processEvent);
  }

  void onPause() {/* user implementation */}
  void onPlay() {/* user implementation */}
  void onComplete() {/* user implementation */}
  void onTime(int position) {/* user implementation */}
  void onSeek(int position, double offset) {/* user implementation */}
  void onError(String error) {/* user implementation */}

  void processEvent(dynamic event) async {
    String eventName = event["name"];

    switch (eventName) {

      /* onPause */
      case "onPause":
        onPause();
        break;

      /* onPlay */
      case "onPlay":
        onPlay();
        break;

      /* onComplete */
      case "onComplete":
        onComplete();
        break;

      /* onTime */
      case "onTime":
        onTime(event["time"].toInt());
        break;

      /* onSeek */
      case "onSeek":

        /* position of the player before the player seeks (in seconds) */
        int position = (event["position"]).toInt();

        /* requested position to seek to (in seconds) */
        double offset = double.parse("${event["offset"]}");

        onSeek(position, offset);

        break;

      case "onError":
        onError(event["error"]);
        break;

      default:
        break;
    }
  }
}
