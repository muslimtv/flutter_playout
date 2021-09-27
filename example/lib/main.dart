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
  final String _url1 =
      "https://player.vimeo.com/external/343735688.hd.mp4?s=583158831c9a4bd25f880ce2b01042ae2e55caa6&profile_id=174";
  final String _url2 = "https://www.rmp-streaming.com/media/big-buck-bunny-360p.mp4";
  String _url;
  bool hideVideo = false;

  @override
  void initState() {
    super.initState();
    _url = _url1;
  }

  PlayerState _desiredState = PlayerState.STOPPED;
  bool _showPlayerControls = true;
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
                hideVideo = !hideVideo;
                // _desiredState = PlayerState.PAUSED;
              });
              // wait for user to come back from navigated screen
              // await Navigator.push(context, MaterialPageRoute<void>(
              //   builder: (context) {
              //     return Scaffold(
              //       appBar: AppBar(),
              //       body: Container(
              //         child: Center(
              //           child: AudioPlayout(
              //             desiredState: _desiredState,
              //           ),
              //         ),
              //       ),
              //     );
              //   },
              // ));
              // user is back. resume playback
//              setState(() {
//                _desiredState = PlayerState.PLAYING;
//              });
            },
          ),
          /* toggle show player controls */
          IconButton(
            icon: Icon(Icons.adjust),
            onPressed: () async {
              setState(() {
                if (_url == _url1)
                  _url = _url2;
                else
                  _url = _url1;

                // _showPlayerControls = !_showPlayerControls;
              });
            },
          ),
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
              style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.white),
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
                  style: Theme.of(context)
                      .textTheme
                      .headline4
                      .copyWith(color: Colors.pink[500], fontWeight: FontWeight.w600),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(17.0, 0.0, 17.0, 30.0),
                child: Text(
                  "Plays video from a URL with background audio support and lock screen controls.",
                  style: Theme.of(context)
                      .textTheme
                      .subtitle1
                      .copyWith(color: Colors.white70, fontWeight: FontWeight.w400),
                ),
              ),
            ),
            SliverToBoxAdapter(
                child: hideVideo
                    ? Container()
                    : VideoPlayout(
                        desiredState: _desiredState,
                        showPlayerControls: _showPlayerControls,
                        url: _url,
                      )),
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(17.0, 23.0, 17.0, 0.0),
                child: Text(
                  "Audio Player",
                  style: Theme.of(context)
                      .textTheme
                      .headline4
                      .copyWith(color: Colors.pink[500], fontWeight: FontWeight.w600),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(17.0, 0.0, 17.0, 30.0),
                child: Text(
                  "Plays audio from a URL with background audio support and lock screen controls.",
                  style: Theme.of(context)
                      .textTheme
                      .subtitle1
                      .copyWith(color: Colors.white70, fontWeight: FontWeight.w400),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: AudioPlayout(
                desiredState: _desiredState,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
