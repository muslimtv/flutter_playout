import 'dart:async';

import 'package:flutter_playout/multiaudio/HLSManifestLanguage.dart';
import 'package:flutter_playout/multiaudio/LanguageCode.dart';
import 'package:http/http.dart' as http;

Future<List<HLSManifestLanguage>> getManifestLanguages(
    String manifestURL) async {
  final response = await http.get(manifestURL);

  final List<String> manifest = response.body.split("\n");

  int start = 7;
  if (manifestURL.startsWith("https")) {
    start = 8;
  }

  String _baseURL = manifestURL.substring(0, manifestURL.indexOf("/", start));
  String _baseURLLastIndex =
      manifestURL.substring(0, manifestURL.lastIndexOf("/"));

  Map<String, HLSManifestLanguage> _langs = Map<String, HLSManifestLanguage>();

  /* iterate through all #EXT-X-MEDIA:TYPE=AUDIO */
  manifest.forEach((m) {
    if (m.startsWith("#EXT-X-MEDIA:TYPE=AUDIO")) {
      List<String> values =
          m.replaceAll("#EXT-X-MEDIA:TYPE=AUDIO,", "").split(",");

      String uri = values
          .where((v) => v.startsWith("URI"))
          .first
          .replaceAll("URI=", "")
          .replaceAll("\"", "");

      var languageCode = values
          .where((v) => v.startsWith("LANGUAGE"))
          .first
          .replaceAll("LANGUAGE=", "")
          .replaceAll("\"", "");

      HLSManifestLanguage language =
          LanguageCode.getLanguageByCode(languageCode);

      if (uri.contains("/")) {
        language.url = _baseURL + uri;
      } else {
        language.url = _baseURLLastIndex + "/" + uri;
      }

      _langs.putIfAbsent(languageCode, () => language);
    }
  });

  /* legacy manifest */
  if (_langs.length < 1) {
    var languageCode = "mul";

    HLSManifestLanguage language = LanguageCode.getLanguageByCode(languageCode);

    manifest.forEach((m) {
      if (m.contains("a-p")) {
        language.url = m;

        _langs.putIfAbsent(languageCode, () => language);
      }
    });
  }

  return _langs.values.toList();
}
