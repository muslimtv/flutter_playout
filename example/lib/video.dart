import 'package:flutter/material.dart';
import 'package:flutter_playout/player_observer.dart';
import 'package:flutter_playout/player_state.dart';
import 'package:flutter_playout/video.dart';

class VideoPlayout extends StatelessWidget with PlayerObserver {
  final PlayerState desiredState;
  final bool showPlayerControls;

  const VideoPlayout({Key key, this.desiredState, this.showPlayerControls})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Video(
          autoPlay: true,
          showControls: showPlayerControls,
          title: "MTA International",
          subtitle: "Reaching The Corners Of The Earth",
          isLiveStream: true,
          url: "https://your_video_stream.com/stream_test.m3u8",
          onViewCreated: _onViewCreated,
          desiredState: desiredState,
        ),
      ),
    );
  }

  void _onViewCreated(int viewId) {
    listenForVideoPlayerEvents(viewId);
  }

  @override
  void onPlay() {
    // TODO: implement onPlay
    super.onPlay();
  }

  @override
  void onPause() {
    // TODO: implement onPause
    super.onPause();
  }

  @override
  void onComplete() {
    // TODO: implement onComplete
    super.onComplete();
  }

  @override
  void onTime(int position) {
    // TODO: implement onTime
    super.onTime(position);
  }

  @override
  void onSeek(int position, double offset) {
    // TODO: implement onSeek
    super.onSeek(position, offset);
  }

  @override
  void onDuration(int duration) {
    // TODO: implement onDuration
    super.onDuration(duration);
  }

  @override
  void onError(String error) {
    // TODO: implement onError
    super.onError(error);
  }
}
