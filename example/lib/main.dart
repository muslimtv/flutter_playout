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
