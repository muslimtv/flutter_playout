import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Video extends StatefulWidget {
  final bool autoPlay;
  final String url;
  final String title;
  final String subtitle;
  final Function onViewCreated;

  const Video(
      {Key key,
      this.autoPlay = false,
      this.url,
      this.title,
      this.subtitle,
      this.onViewCreated})
      : super(key: key);

  @override
  _VideoState createState() => _VideoState();
}

class _VideoState extends State<Video> {
  int _platformViewId;

  @override
  Widget build(BuildContext context) {
    Widget playerWidget = Container();

    /* setup player */
    if (widget.url != null && widget.url.isNotEmpty) {
      /* Android */
      if (Platform.isAndroid) {
        playerWidget = AndroidView(
          viewType: 'tv.mta/NativeVideoPlayer',
          creationParams: {
            "autoPlay": widget.autoPlay,
            "url": widget.url,
            "title": widget.title ?? "",
            "subtitle": widget.subtitle ?? "",
          },
          creationParamsCodec: const JSONMessageCodec(),
          onPlatformViewCreated: (viewId) {
            _platformViewId = viewId;
            widget.onViewCreated(viewId);
          },
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
            new Factory<OneSequenceGestureRecognizer>(
              () => new EagerGestureRecognizer(),
            ),
          ].toSet(),
        );
      }

      /* iOS */
      else if (Platform.isIOS) {
        playerWidget = UiKitView(
          viewType: 'tv.mta/NativeVideoPlayer',
          creationParams: {
            "autoPlay": widget.autoPlay,
            "url": widget.url,
            "title": widget.title ?? "",
            "subtitle": widget.subtitle ?? "",
          },
          creationParamsCodec: const JSONMessageCodec(),
          onPlatformViewCreated: (viewId) {
            _platformViewId = viewId;
            widget.onViewCreated(viewId);
          },
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
            new Factory<OneSequenceGestureRecognizer>(
              () => new EagerGestureRecognizer(),
            ),
          ].toSet(),
        );
      }
    } else {
      _disposePlatformView(_platformViewId);
    }

    return GestureDetector(
      onTap: () {},
      child: playerWidget,
    );
  }

  @override
  void dispose() {
    _disposePlatformView(_platformViewId, isDisposing: true);
    super.dispose();
  }

  void _disposePlatformView(int viewId, {bool isDisposing = false}) {
    if (viewId != null) {
      var methodChannel =
          MethodChannel("tv.mta/NativeVideoPlayerEventChannel_${viewId}");

      /* clean platform view */
      methodChannel.invokeMethod("dispose");

      if (!isDisposing) {
        setState(() {
          _platformViewId = null;
        });
      }
    }
  }
}
