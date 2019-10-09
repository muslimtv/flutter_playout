# How to use flutter_playout
Below is an example app showcasing both video and audio players from this plugin.

## main.dart
```dart
import 'package:flutter/material.dart';

import 'package:flutter_playout_example/audio.dart';
import 'package:flutter_playout_example/video.dart';

void main() => runApp(PlayoutExample());

class PlayoutExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "AV Playout",
      home: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          brightness: Brightness.dark,
          backgroundColor: Colors.grey[900],
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {},
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.favorite),
              onPressed: () {},
            )
          ],
          title: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.local_play,
                color: Colors.white,
              ),
              Container(
                width: 7.0,
              ),
              Text(
                "AV Player",
                style: Theme.of(context)
                    .textTheme
                    .title
                    .copyWith(color: Colors.white),
              )
            ],
          ),
        ),
        body: Container(
          color: Colors.black,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.fromLTRB(17.0, 33.0, 17.0, 0.0),
                  child: Text(
                    "Video Player",
                    style: Theme.of(context).textTheme.display1.copyWith(
                        color: Colors.pink[500], fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.fromLTRB(17.0, 0.0, 17.0, 30.0),
                  child: Text(
                    "Plays video from a URL with background audio support and lock screen controls.",
                    style: Theme.of(context).textTheme.subhead.copyWith(
                        color: Colors.white70, fontWeight: FontWeight.w400),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: VideoPlayout(),
              ),
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.fromLTRB(17.0, 23.0, 17.0, 0.0),
                  child: Text(
                    "Audio Player",
                    style: Theme.of(context).textTheme.display1.copyWith(
                        color: Colors.pink[500], fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.fromLTRB(17.0, 0.0, 17.0, 30.0),
                  child: Text(
                    "Plays audio from a URL with background audio support and lock screen controls.",
                    style: Theme.of(context).textTheme.subhead.copyWith(
                        color: Colors.white70, fontWeight: FontWeight.w400),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: AudioPlayout(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

```

## Video Playout
#### package:flutter_playout_example/video.dart

```dart
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

```
## Audio Playout 
#### package:flutter_playout_example/audio.dart
```dart
import 'package:flutter/material.dart';

import 'package:flutter_playout/audio.dart';
import 'package:flutter_playout/player_state.dart';
import 'package:flutter_playout/player_observer.dart';

class AudioPlayout extends StatefulWidget {
  // Audio url to play
  final String url = "https://your_audio_stream.com/stream_test.mp3";

  // Audio track title. this will also be displayed in lock screen controls
  final String title = "MTA International";

  // Audio track subtitle. this will also be displayed in lock screen controls
  final String subtitle = "Reaching The Corners Of The Earth";

  // Audio duration in milliseconds
  final int duration = 1604277;

  @override
  _AudioPlayout createState() => _AudioPlayout();
}

class _AudioPlayout extends State<AudioPlayout> with PlayerObserver {
  Audio _audioPlayer;
  PlayerState audioPlayerState = PlayerState.STOPPED;

  Duration duration = Duration(milliseconds: 1);
  Duration position = Duration.zero;

  get isPlaying => audioPlayerState == PlayerState.PLAYING;
  get isPaused =>
      audioPlayerState == PlayerState.PAUSED ||
      audioPlayerState == PlayerState.STOPPED;

  get durationText =>
      duration != null ? duration.toString().split('.').first : '';
  get positionText =>
      position != null ? position.toString().split('.').first : '';

  @override
  void initState() {
    super.initState();

    // Set track duration
    duration = Duration(milliseconds: widget.duration);

    // Init audio player with a callback to handle events
    _audioPlayer = new Audio(processAudioEvents);

    // Listen for audio player events
    listenForAudioPlayerEvents();
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[900],
      child: _buildPlayerControls(),
    );
  }

  Widget _buildPlayerControls() {
    return Container(
      color: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                splashColor: Colors.transparent,
                icon: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.white,
                  size: 50,
                ),
                onPressed: () {
                  if (isPlaying) {
                    pause();
                  } else {
                    play();
                  }
                },
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.fromLTRB(20.0, 11.0, 5.0, 3.0),
                    child: Text(widget.title,
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[100])),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(20.0, 0.0, 5.0, 0.0),
                    child: Text(widget.subtitle,
                        style: TextStyle(fontSize: 19, color: Colors.white)),
                  ),
                ],
              )
            ],
          ),
          Container(
            height: 15.0,
          ),
          Slider(
            activeColor: Colors.white,
            value: position?.inMilliseconds?.toDouble() ?? 0.0,
            onChanged: (double value) {
              setState(() {
                position = Duration(milliseconds: value.toInt());
              });
              seekTo(value / 1000);
            },
            min: 0.0,
            max: duration.inMilliseconds.toDouble(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(),
              Container(
                padding: EdgeInsets.fromLTRB(20, 5, 20, 10),
                child: Text(
                  _playbackPositionString(),
                  style: Theme.of(context)
                      .textTheme
                      .body1
                      .copyWith(color: Colors.white),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  String _playbackPositionString() {
    var currentPosition = Duration(
        milliseconds: duration.inMilliseconds - position.inMilliseconds);

    return currentPosition.toString().split('.').first;
  }

  // Request audio play
  Future<void> play() async {
    // here we send position in case user has scrubbed already before hitting play
    // in which case we want playback to start from where user has requested
    _audioPlayer.play(
        widget.url, widget.title, widget.subtitle, widget.duration, position);
    setState(() {
      audioPlayerState = PlayerState.PLAYING;
    });
  }

  // Request audio pause
  Future<void> pause() async {
    _audioPlayer.pause();
    setState(() => audioPlayerState = PlayerState.PAUSED);
  }

  // Request audio stop. this will also clear lock screen controls
  Future<void> stop() async {
    _audioPlayer.stop();

    setState(() {
      audioPlayerState = PlayerState.STOPPED;
      position = Duration.zero;
    });
  }

  // Seek to a point in seconds
  Future<void> seekTo(double seconds) async {
    _audioPlayer.seekTo(seconds);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // Callback for player events
  void processAudioEvents(dynamic event) async {
    String eventName = event["name"];

    switch (eventName) {

      /* onTime - fires every second */
      case "onTime":
        setState(() {
          position = Duration(seconds: event["time"].toInt());
        });

        /* reset on playback end */
        if (position.inSeconds > 0 &&
            position.inSeconds >= duration.inSeconds) {
          stop();
        }

        break;

      /* onPause */
      case "onPause":
        setState(() {
          audioPlayerState = PlayerState.PAUSED;
        });

        break;

      /* onPlay */
      case "onPlay":
        setState(() {
          audioPlayerState = PlayerState.PLAYING;
        });

        break;
    }
  }
}

```