import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Video plugin for playing HLS stream using native player. [autoPlay] flag
/// controls whether to start playback as soon as player is ready. The [title]
/// and [subtitle] are used for lock screen info panel on both iOS & Android.
/// The [isLiveStream] flag is only used on iOS to change the scrub-bar look
/// on lock screen info panel. It has no affect on the actual functionality
/// of the plugin. Defaults to false.
class Video extends StatefulWidget {
  final bool autoPlay;
  final String url;
  final String title;
  final String subtitle;
  final bool isLiveStream;
  final Function onViewCreated;

  const Video(
      {Key key,
      this.autoPlay = false,
      this.url,
      this.title = "",
      this.subtitle = "",
      this.isLiveStream = false,
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
            "isLiveStream": widget.isLiveStream,
          },
          creationParamsCodec: const JSONMessageCodec(),
          onPlatformViewCreated: (viewId) {
            _platformViewId = viewId;
            if (widget.onViewCreated != null) {
              widget.onViewCreated(viewId);
            }
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
            "isLiveStream": widget.isLiveStream,
          },
          creationParamsCodec: const JSONMessageCodec(),
          onPlatformViewCreated: (viewId) {
            _platformViewId = viewId;
            if (widget.onViewCreated != null) {
              widget.onViewCreated(viewId);
            }
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
  void didUpdateWidget(Video oldWidget) {
    if (oldWidget.url != widget.url ||
        oldWidget.title != widget.title ||
        oldWidget.subtitle != widget.subtitle ||
        oldWidget.isLiveStream != widget.isLiveStream) {
      _onMediaChanged(_platformViewId);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _disposePlatformView(_platformViewId, isDisposing: true);
    super.dispose();
  }

  void _onMediaChanged(int viewId) {
    if (viewId != null && widget.url != null) {
      var methodChannel =
          MethodChannel("tv.mta/NativeVideoPlayerMethodChannel_$viewId");
      methodChannel.invokeMethod("onMediaChanged", {
        "autoPlay": widget.autoPlay,
        "url": widget.url,
        "title": widget.title,
        "subtitle": widget.subtitle,
        "isLiveStream": widget.isLiveStream,
      });
    }
  }

  void _disposePlatformView(int viewId, {bool isDisposing = false}) {
    if (viewId != null) {
      var methodChannel =
          MethodChannel("tv.mta/NativeVideoPlayerMethodChannel_$viewId");

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
