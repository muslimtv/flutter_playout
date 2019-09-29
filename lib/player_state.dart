/// Communicates the current state of the player.
enum PlayerState {
  /// Player is stopped. No file is loaded to the player. Calling [resume] or
  /// [pause] will result in exception.
  STOPPED,
  /// Currently playing a file. The user can [pause], [resume] or [stop] the
  /// playback.
  PLAYING,
  /// Paused. The user can [resume] the playback without providing the URL.
  PAUSED,
  /// The playback has been completed. This state is the same as [STOPPED],
  /// however we differentiate it because some clients might want to know when
  /// the playback is done versus when the user has stopped the playback.
  COMPLETED,
}