import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_playout/player_state.dart';
import 'package:flutter_playout/textTrack.dart';

/// Video plugin for playing HLS stream using native player. [autoPlay] flag
/// controls whether to start playback as soon as player is ready. To show/hide
/// player controls, use [showControls] flag. The [title] and [subtitle] are
/// used for lock screen info panel on both iOS & Android. The [isLiveStream]
/// flag is only used on iOS to change the scrub-bar look on lock screen info
/// panel. It has no affect on the actual functionality of the plugin. Defaults
/// to false. Use [preferredAudioLanguage] to set select HLS manifest language
/// on player init. If the [preferredAudioLanguage] value changes during widget
/// rebuild, the player would automatically switch to new language. Use position
/// to set start position for player seek bar. Changing [position] during widget
/// rebuild will make player seek to new position. Use [onViewCreated] callback
/// to get notified once the underlying [PlatformView] is setup. The
/// [desiredState] enum can be used to control play/pause. If the value change,
/// the widget will make sure that player is in sync with the new state. Use
/// [textTracks] to pass a list of [TextTrack] sources to the player (optional).
/// This is only used for Android ExoPlayer. For iOS please embed text tracks
/// into the HLS manifest, no more configuration required on iOS side.
class Video extends StatefulWidget {
  final bool autoPlay;
  final bool loop;
  final bool showControls;
  final String? url;
  final String? title;
  final String? subtitle;
  final String? preferredAudioLanguage;
  final List<TextTrack>? textTracks;
  final String? preferredTextLanguage;
  final bool isLiveStream;
  final double position;
  final Function? onViewCreated;
  final PlayerState desiredState;

  const Video(
      {Key? key,
      this.autoPlay = false,
      this.loop = false,
      this.showControls = true,
      this.url,
      this.title = "",
      this.subtitle = "",
      this.preferredAudioLanguage = "mul",
      this.preferredTextLanguage = "",
      this.isLiveStream = false,
      this.position = -1,
      this.onViewCreated,
      this.desiredState = PlayerState.PLAYING,
      this.textTracks})
      : super(key: key);

  @override
  _VideoState createState() => _VideoState();
}

class _VideoState extends State<Video> {
  MethodChannel? _methodChannel;
  int? _platformViewId;
  Widget _playerWidget = Container();

  @override
  void initState() {
    super.initState();
    _setupPlayer();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: _playerWidget,
    );
  }

  void _setupPlayer() {
    if (widget.url != null && widget.url!.isNotEmpty) {
      /* Android */
      if (Platform.isAndroid) {
        _playerWidget = AndroidView(
          viewType: 'tv.mta/NativeVideoPlayer',
          creationParams: {
            "autoPlay": widget.autoPlay,
            "loop": widget.loop,
            "showControls": widget.showControls,
            "url": widget.url,
            "title": widget.title ?? "",
            "subtitle": widget.subtitle ?? "",
            "preferredAudioLanguage": widget.preferredAudioLanguage ?? "mul",
            "isLiveStream": widget.isLiveStream,
            "position": widget.position,
            "textTracks": TextTrack.toJsonFromList(widget.textTracks ?? []),
            "preferredTextLanguage": widget.preferredTextLanguage ?? "",
          },
          creationParamsCodec: const JSONMessageCodec(),
          onPlatformViewCreated: (viewId) {
            _onPlatformViewCreated(viewId);
            if (widget.onViewCreated != null) {
              widget.onViewCreated!(viewId);
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
        _playerWidget = UiKitView(
          viewType: 'tv.mta/NativeVideoPlayer',
          creationParams: {
            "autoPlay": widget.autoPlay,
            "loop": widget.loop,
            "showControls": widget.showControls,
            "url": widget.url,
            "title": widget.title ?? "",
            "subtitle": widget.subtitle ?? "",
            "preferredAudioLanguage": widget.preferredAudioLanguage ?? "mul",
            "isLiveStream": widget.isLiveStream,
            "position": widget.position,
          },
          creationParamsCodec: const JSONMessageCodec(),
          onPlatformViewCreated: (viewId) {
            _onPlatformViewCreated(viewId);
            if (widget.onViewCreated != null) {
              widget.onViewCreated!(viewId);
            }
          },
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
            new Factory<OneSequenceGestureRecognizer>(
              () => new EagerGestureRecognizer(),
            ),
          ].toSet(),
        );
      }
    }
  }

  @override
  void didUpdateWidget(Video oldWidget) {
    if (widget.url == null || widget.url!.isEmpty) {
      _disposePlatformView();
    }
    if (oldWidget.url != widget.url ||
        oldWidget.title != widget.title ||
        oldWidget.subtitle != widget.subtitle ||
        oldWidget.isLiveStream != widget.isLiveStream) {
      _onMediaChanged();
    }
    if (oldWidget.desiredState != widget.desiredState) {
      _onDesiredStateChanged(oldWidget);
    }
    if (oldWidget.showControls != widget.showControls) {
      _onShowControlsFlagChanged();
    }
    if (oldWidget.preferredAudioLanguage != widget.preferredAudioLanguage) {
      _onPreferredAudioLanguageChanged();
    }
    if (oldWidget.preferredTextLanguage != widget.preferredTextLanguage) {
      _onPreferredTextLanguageChanged();
    }
    if (oldWidget.position != widget.position && widget.position >= 0) {
      _onSeekPositionChanged();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _disposePlatformView(isDisposing: true);
    super.dispose();
  }

  void _onPlatformViewCreated(int viewId) {
    _platformViewId = viewId;
    _methodChannel =
        MethodChannel("tv.mta/NativeVideoPlayerMethodChannel_$viewId");
  }

  /// The [desiredState] flag has changed so need to update playback to
  /// reflect the new state.
  void _onDesiredStateChanged(Video oldWidget) async {
    switch (widget.desiredState) {
      case PlayerState.PLAYING:
        _resumePlayback();
        break;
      case PlayerState.PAUSED:
        _pausePlayback();
        break;
      case PlayerState.STOPPED:
        _pausePlayback();
        break;
    }
  }

  void _onShowControlsFlagChanged() async {
    _methodChannel!.invokeMethod("onShowControlsFlagChanged", {
      "showControls": widget.showControls,
    });
  }

  void _onPreferredAudioLanguageChanged() async {
    if (_methodChannel != null &&
        widget.preferredAudioLanguage != null &&
        widget.preferredAudioLanguage!.isNotEmpty &&
        !Platform.isIOS) {
      _methodChannel!.invokeMethod(
          "setPreferredAudioLanguage", {"code": widget.preferredAudioLanguage});
    }
  }

  void _onPreferredTextLanguageChanged() async {
    if (_methodChannel != null &&
        widget.preferredTextLanguage != null &&
        !Platform.isIOS) {
      _methodChannel!.invokeMethod(
          "setPreferredTextLanguage", {"code": widget.preferredTextLanguage});
    }
  }

  void _onSeekPositionChanged() async {
    if (_methodChannel != null) {
      _methodChannel!.invokeMethod("seekTo", {"position": widget.position});
    }
  }

  void _pausePlayback() async {
    if (_methodChannel != null) {
      _methodChannel!.invokeMethod("pause");
    }
  }

  void _resumePlayback() async {
    if (_methodChannel != null) {
      _methodChannel!.invokeMethod("resume");
    }
  }

  void _onMediaChanged() {
    if (widget.url != null) {
      if (_methodChannel == null) {
        _setupPlayer();
      } else {
        _methodChannel!.invokeMethod("onMediaChanged", {
          "autoPlay": widget.autoPlay,
          "loop": widget.loop,
          "url": widget.url,
          "title": widget.title,
          "subtitle": widget.subtitle,
          "isLiveStream": widget.isLiveStream,
          "showControls": widget.showControls,
          "position": widget.position,
        });
      }
    }
  }

  void _disposePlatformView({bool isDisposing = false}) async {
    if (_methodChannel != null && _platformViewId != null) {
      _methodChannel!.invokeMethod("dispose");

      if (!isDisposing) {
        setState(() {
          _methodChannel = null;
        });
      }
    }
  }
}
