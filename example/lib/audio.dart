import 'package:flutter/material.dart';
import 'package:flutter_playout/audio.dart';
import 'package:flutter_playout/player_observer.dart';
import 'package:flutter_playout/player_state.dart';

class AudioPlayout extends StatefulWidget {
  // Audio url to play
  final String url = "https://your_audio_stream.com/stream_test.mp3";

  // Audio track title. this will also be displayed in lock screen controls
  final String title = "MTA International";

  // Audio track subtitle. this will also be displayed in lock screen controls
  final String subtitle = "Reaching The Corners Of The Earth";

  @override
  _AudioPlayout createState() => _AudioPlayout();
}

class _AudioPlayout extends State<AudioPlayout> with PlayerObserver {
  Audio _audioPlayer;
  PlayerState audioPlayerState = PlayerState.STOPPED;

  Duration duration = Duration(milliseconds: 1);
  Duration currentPlaybackPosition = Duration.zero;

  get isPlaying => audioPlayerState == PlayerState.PLAYING;
  get isPaused =>
      audioPlayerState == PlayerState.PAUSED ||
      audioPlayerState == PlayerState.STOPPED;

  get durationText =>
      duration != null ? duration.toString().split('.').first : '';
  get positionText => currentPlaybackPosition != null
      ? currentPlaybackPosition.toString().split('.').first
      : '';

  @override
  void initState() {
    super.initState();

    // Init audio player with a callback to handle events
    _audioPlayer = new Audio();

    // Listen for audio player events
    listenForAudioPlayerEvents();
  }

  @override
  void onPlay() {
    setState(() {
      audioPlayerState = PlayerState.PLAYING;
    });
  }

  @override
  void onPause() {
    setState(() {
      audioPlayerState = PlayerState.PAUSED;
    });
  }

  @override
  void onComplete() {
    stop();
  }

  @override
  void onTime(int position) {
    setState(() {
      currentPlaybackPosition = Duration(seconds: position);
    });
  }

  @override
  void onSeek(int position, double offset) {
    super.onSeek(position, offset);
  }

  @override
  void onDuration(int duration) {
    setState(() {
      this.duration = Duration(milliseconds: duration);
    });
  }

  @override
  void onError(String error) {
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
            value: currentPlaybackPosition?.inMilliseconds?.toDouble() ?? 0.0,
            onChanged: (double value) {
              setState(() {
                currentPlaybackPosition = Duration(milliseconds: value.toInt());
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
        seconds: duration.inSeconds - currentPlaybackPosition.inSeconds);

    return currentPosition.toString().split('.').first;
  }

  // Request audio play
  Future<void> play() async {
    // here we send position in case user has scrubbed already before hitting
    // play in which case we want playback to start from where user has
    // requested
    _audioPlayer.play(widget.url,
        title: widget.title,
        subtitle: widget.subtitle,
        position: currentPlaybackPosition,
        isLiveStream: true);
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
      currentPlaybackPosition = Duration.zero;
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
}
