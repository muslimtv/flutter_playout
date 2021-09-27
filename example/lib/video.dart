import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_playout/multiaudio/HLSManifestLanguage.dart';
import 'package:flutter_playout/multiaudio/MultiAudioSupport.dart';
import 'package:flutter_playout/player_observer.dart';
import 'package:flutter_playout/player_state.dart';
import 'package:flutter_playout/video.dart';

class VideoPlayout extends StatefulWidget {
  final PlayerState desiredState;
  final bool showPlayerControls;
  final String url;
  const VideoPlayout({Key key, this.desiredState, this.showPlayerControls, this.url}) : super(key: key);

  @override
  _VideoPlayoutState createState() => _VideoPlayoutState();
}

class _VideoPlayoutState extends State<VideoPlayout> with PlayerObserver, MultiAudioSupport {
  final String _url =
      "https://player.vimeo.com/external/343735688.hd.mp4?s=583158831c9a4bd25f880ce2b01042ae2e55caa6&profile_id=174";
  // final String _url = "https://www.rmp-streaming.com/media/big-buck-bunny-360p.mp4";
  // "https://firebasestorage.googleapis.com/v0/b/upliftnow-dev.appspot.com/o/courses%2F-M66CPTTGRpt5jW4otna%2F-M66CPTVJUyZHce4QW3g%2F9d5ddc39-d2e1-4b1e-bab2-de175415d811.mp4?alt=media&token=a5e1c499-375b-4ad6-984c-fa91de7a49ad";
  List<HLSManifestLanguage> _hlsLanguages = [];

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, _getHLSManifestLanguages);
  }

  Future<void> _getHLSManifestLanguages() async {
    // if (!Platform.isIOS && _url != null && _url.isNotEmpty) {
    //   _hlsLanguages = await getManifestLanguages(_url);
    //   setState(() {});
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          /* player */
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Video(
              autoPlay: false,
              showControls: widget.showPlayerControls,
              title: "MTA International",
              subtitle: "Reaching The Corners Of The Earth",
              preferredAudioLanguage: "eng",
              isLiveStream: false,
              position: 0,
              url: widget.url,
              onViewCreated: _onViewCreated,
              desiredState: widget.desiredState,
              preferredTextLanguage: "en",
              loop: false,
              artworkUrl:
                  "https://firebasestorage.googleapis.com/v0/b/upliftnow-dev.appspot.com/o/category_images%2Fthealcoholexperiment%2F1b127c64-7c28-4c1a-9835-5ae8e23afafc.jpg",
              // artworkUrl:
              //     "https://firebasestorage.googleapis.com/v0/b/upliftnow-dev.appspot.com/o/category_images%2Fthealcoholexperiment%2F1b127c64-7c28-4c1a-9835-5ae8e23afafc.jpg?alt=media&token=7679e470-64b4-4a66-a4b8-6e6c4c521053",
            ),
          ),
          /* multi language menu */
          _hlsLanguages.length < 2 && !Platform.isIOS
              ? Container()
              : Container(
                  child: Row(
                    children: _hlsLanguages
                        .map((e) => MaterialButton(
                              child: Text(
                                e.name,
                                style: Theme.of(context).textTheme.button.copyWith(color: Colors.white),
                              ),
                              onPressed: () {
                                setPreferredAudioLanguage(e.code);
                              },
                            ))
                        .toList(),
                  ),
                ),
        ],
      ),
    );
  }

  void _onViewCreated(int viewId) {
    listenForVideoPlayerEvents(viewId);
    enableMultiAudioSupport(viewId);
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
