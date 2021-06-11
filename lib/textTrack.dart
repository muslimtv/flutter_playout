/// Used for adding text tracks to the player. [mimetype] is the type of text
/// track for example text/webvtt. [languageCode] is the language of the track
/// for example `en` or `fr` and [uri] is the location for the track.
class TextTrack {
  final String mimetype;
  final String languageCode;
  final String uri;

  TextTrack(this.mimetype, this.languageCode, this.uri);

  factory TextTrack.from(
      {required String mimetype,
      required String languageCode,
      required String uri}) {
    return new TextTrack(mimetype, languageCode, uri);
  }

  Map<String, dynamic> toJson() {
    return {
      "mimeType": mimetype,
      "languageCode": languageCode,
      "uri": uri,
    };
  }

  static List<dynamic> toJsonFromList(List<TextTrack> tracks) {
    return tracks.map((t) => t.toJson()).toList();
  }
}
