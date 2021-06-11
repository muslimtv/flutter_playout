class HLSManifestLanguage {
  final String? code;
  final String? name;
  final String? nativeName;
  String? url;

  HLSManifestLanguage(this.code, this.name, {this.nativeName, this.url});

  factory HLSManifestLanguage.fromJson(Map<String, dynamic> json) {
    return HLSManifestLanguage(
      json["code"],
      json["name"],
      nativeName: json["nativeName"],
      url: json["url"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'nativeName': nativeName,
      'url': url,
    };
  }

  static List<dynamic> toJsonFromList(List<HLSManifestLanguage> languages) {
    return languages.map((a) => a.toJson()).toList();
  }
}
