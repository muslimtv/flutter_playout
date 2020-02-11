class HLSManifestLanguage {
  final String code;
  final String name;
  String url;

  HLSManifestLanguage(this.code, this.name, {this.url});

  factory HLSManifestLanguage.fromJson(Map<String, dynamic> json) {
    return HLSManifestLanguage(
      json["code"],
      json["name"],
      url: json["url"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'url': url,
    };
  }

  static List<dynamic> toJsonFromList(List<HLSManifestLanguage> languages) {
    if (languages == null) return List<dynamic>();
    return languages.map((a) => a.toJson()).toList();
  }
}
