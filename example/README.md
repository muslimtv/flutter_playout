# How to use flutter_playout
Below is an example app showcasing both video and audio players from this plugin.

## main.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_playout/player_state.dart';
import 'package:flutter_playout_example/audio.dart';
import 'package:flutter_playout_example/video.dart';

void main() => runApp(MainApp());

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "AV Playout",
      home: PlayoutExample(),
    );
  }
}

class PlayoutExample extends StatefulWidget {
  @override
  _PlayoutExampleState createState() => _PlayoutExampleState();
}

class _PlayoutExampleState extends State<PlayoutExample> {
  PlayerState _desiredState = PlayerState.PLAYING;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            onPressed: () async {
              // pause playback
              setState(() {
                _desiredState = PlayerState.PAUSED;
              });
              // wait for user to come back from navigated screen
              await Navigator.push(context, MaterialPageRoute<void>(
                builder: (context) {
                  return Scaffold(
                    appBar: AppBar(),
                    body: Container(
                      child: Center(
                        child: Text("Second Screen"),
                      ),
                    ),
                  );
                },
              ));
              // user is back. resume playback
              setState(() {
                _desiredState = PlayerState.PLAYING;
              });
            },
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
                child: VideoPlayout(
              desiredState: _desiredState,
            )),
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
    );
  }
}

```

## Video Playout
#### package:flutter_playout_example/video.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_playout/player_observer.dart';
import 'package:flutter_playout/player_state.dart';
import 'package:flutter_playout/video.dart';

class VideoPlayout extends StatelessWidget with PlayerObserver {
  final PlayerState desiredState;

  const VideoPlayout({Key key, this.desiredState}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Video(
          autoPlay: true,
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

```
## Audio Playout 
#### package:flutter_playout_example/audio.dart
```dart
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
  bool _loading = false;

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
      _loading = false;
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
    setState(() {
      audioPlayerState = PlayerState.PAUSED;
      currentPlaybackPosition = Duration.zero;
    });
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
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: EdgeInsets.fromLTRB(0.0, 11.0, 0.0, 0.0),
                margin: EdgeInsets.all(7.0),
                child: Stack(
                  children: <Widget>[
                    IconButton(
                      padding: EdgeInsets.all(0.0),
                      splashColor: Colors.transparent,
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: Colors.white,
                        size: 47,
                      ),
                      onPressed: () {
                        if (isPlaying) {
                          pause();
                        } else {
                          play();
                        }
                      },
                    ),
                    _loading
                        ? Positioned.fill(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Container(),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.fromLTRB(7.0, 11.0, 5.0, 3.0),
                    child: Text(widget.title,
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[100])),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(7.0, 0.0, 5.0, 0.0),
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
    setState(() {
      _loading = true;
    });
    // here we send position in case user has scrubbed already before hitting
    // play in which case we want playback to start from where user has
    // requested
    print(currentPlaybackPosition);
    _audioPlayer.play(widget.url,
        title: widget.title,
        subtitle: widget.subtitle,
        position: currentPlaybackPosition,
        isLiveStream: true);
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

```