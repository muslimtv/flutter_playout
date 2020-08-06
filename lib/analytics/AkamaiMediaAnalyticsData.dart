import 'dart:collection';

class AkamaiMediaAnalyticsData {
  Map<String, String> _customData;

  AkamaiMediaAnalyticsData() {
    _customData = HashMap<String, String>();
  }

  AkamaiMediaAnalyticsData withViewerId(String viewerId) {
    _customData.putIfAbsent("viewerId", () => viewerId);
    return this;
  }

  AkamaiMediaAnalyticsData withViewerDiagnosticsId(String viewerDiagnosticsId) {
    _customData.putIfAbsent("viewerDiagnosticsId", () => viewerDiagnosticsId);
    return this;
  }

  /// Title Name
  AkamaiMediaAnalyticsData withTitle(String title) {
    _customData.putIfAbsent("title", () => title);
    return this;
  }

  /// Should not contain more than 10 distinct values because reports will
  /// not be very useful if cardinality for this field is high. Examples
  /// would be; Movies, TV Shows, Documentaries, etc.
  AkamaiMediaAnalyticsData withCategory(String category) {
    _customData.putIfAbsent("category", () => category);
    return this;
  }

  /// Should not contain more than 30 distinct values. Examples would be;
  /// Drama, Comedy, Action, etc. for Movies or Crime Drama, Other Drama,
  /// Sitcom, Soaps, News, etc. for TV Shows.
  AkamaiMediaAnalyticsData withSubCategory(String subCategory) {
    _customData.putIfAbsent("subCategory", () => subCategory);
    return this;
  }

  /// Should be used if the content falls into episodic type periodically
  /// broadcast content.
  AkamaiMediaAnalyticsData withShow(String show) {
    _customData.putIfAbsent("show", () => show);
    return this;
  }

  /// Use this to set the length of content.
  AkamaiMediaAnalyticsData withContentLength(String contentLength) {
    _customData.putIfAbsent("contentLength", () => contentLength);
    return this;
  }

  /// Use this to set the type of content.
  AkamaiMediaAnalyticsData withContentType(String contentType) {
    _customData.putIfAbsent("contentType", () => contentType);
    return this;
  }

  /// Use this to set the device used.
  AkamaiMediaAnalyticsData withDevice(String device) {
    _customData.putIfAbsent("device", () => device);
    return this;
  }

  /// Live VOD 24x7
  /// Inferred automatically if not provided.
  /// Allowed Values ~> O,L,T
  AkamaiMediaAnalyticsData withDeliveryType(DeliveryType deliveryType) {
    String dType;
    if (deliveryType == DeliveryType.L) {
      dType = "L";
    } else if (deliveryType == DeliveryType.T) {
      dType = "T";
    } else {
      dType = "O";
    }
    _customData.putIfAbsent("deliveryType", () => dType);
    return this;
  }

  /// Typically the player’s unique ID meant to identify the player if it
  /// varies by site or property
  AkamaiMediaAnalyticsData withPlayerId(String playerId) {
    _customData.putIfAbsent("playerId", () => playerId);
    return this;
  }

  /// Example; E3
  AkamaiMediaAnalyticsData withEventName(String eventName) {
    _customData.putIfAbsent("eventName", () => eventName);
    return this;
  }

  /// Use this to add any custom data
  AkamaiMediaAnalyticsData withCustomData(String key, String value) {
    _customData.putIfAbsent(key, () => value);
    return this;
  }

  /// Enable debug logging
  AkamaiMediaAnalyticsData withDebugLogging() {
    _customData.putIfAbsent("withDebugLogging", () => "true");
    return this;
  }

  Map<String, String> build() {
    return _customData;
  }
}

enum DeliveryType {
  /// VoD
  O,

  /// Live
  L,

  /// 24x7
  T
}
