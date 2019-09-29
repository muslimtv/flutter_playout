import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_playout/audio.dart';
import 'package:flutter_playout/player_state.dart';

void main() => runApp(AudioPlayoutApp());

class AudioPlayoutApp extends StatefulWidget {
  // Audio url to play
  final String url = "https://your_audio_stream.com/stream_test.mp3";

  // Audio track title. this will also be displayed in lock screen controls
  final String title = "Track Title";

  // Audio track subtitle. this will also be displayed in lock screen controls
  final String subtitle = "Track Subtitle";

  // Audio duration in milliseconds
  final int duration = 1604277;

  @override
  _AudioPlayoutApp createState() => _AudioPlayoutApp();
}

class _AudioPlayoutApp extends State<AudioPlayoutApp> {
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
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "AV Playout",
      home: Scaffold(
        appBar: AppBar(),
        body: Container(
          color: Colors.black,
          child: _buildPlayerControls(),
        ),
      ),
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
                        style: TextStyle(fontSize: 9, color: Colors.grey[100])),
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
