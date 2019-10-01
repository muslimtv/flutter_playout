/// Communicates the current state of the player.
enum PlayerState {
  /// Player is stopped
  STOPPED,

  /// Currently playing. The user can [pause] or [resume] the playback.
  PLAYING,

  /// Paused. The user can [resume] the playback without providing the URL.
  PAUSED,
}
