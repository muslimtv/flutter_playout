import 'dart:io';

import 'package:flutter/services.dart';

/// Use with Video widget for Android only to add multi audio support
/// for HLS manifest. Use [setPreferredAudioLanguage] to set/change
/// language for the currently playing asset.
mixin MultiAudioSupport {
  MethodChannel? _methodChannel;
  Future<void> enableMultiAudioSupport(int viewId) async {
    _methodChannel =
        MethodChannel("tv.mta/NativeVideoPlayerMethodChannel_$viewId");
  }

  /// Set/Change audio language for currently playing asset. [languageCode]
  /// is based on ISO_639_2 language codes. Please see
  /// [lib/multiaudio/ISO_639_2_LanguageCode.dart]
  void setPreferredAudioLanguage(String languageCode) async {
    if (_methodChannel != null && languageCode.isNotEmpty && !Platform.isIOS) {
      _methodChannel!.invokeListMethod(
          "setPreferredAudioLanguage", {"code": languageCode});
    }
  }
}
