import 'package:flutter/material.dart';

import 'package:flutter_playout/video.dart';
import 'package:flutter_playout/player_observer.dart';

class VideoPlayout extends StatelessWidget with PlayerObserver {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Video(
          autoPlay: true,
          title: "Reaching The Corners Of The Earth",
          subtitle: "MTA International",
          url: "https://your_video_stream.com/stream_test.m3u8",
          onViewCreated: _onViewCreated,
        ),
      ),
    );
  }

  // Start listening for player events
  void _onViewCreated(int viewId) {
    listenForVideoPlayerEvents(viewId);
  }

  @override
  void onPlay() {
    // TODO: implement m_onPlay
    super.onPlay();
  }

  @override
  void onPause() {
    // TODO: implement m_onPause
    super.onPause();
  }

  @override
  void onComplete() {
    // TODO: implement m_onComplete
    super.onComplete();
  }

  @override
  void onTime(int position) {
    // TODO: implement m_onTime
    super.onTime(position);
  }

  @override
  void onSeek(int position, double offset) {
    // TODO: implement m_onSeek
    super.onSeek(position, offset);
  }

  @override
  void onError(String error) {
    // TODO: implement m_onError
    super.onError(error);
  }
}
