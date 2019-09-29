package tv.mta.flutter_playout;

public enum PlayerState {
    IDLE,
    BUFFERING,
    PLAYING,
    PAUSED,
    COMPLETE;

    private PlayerState() {
    }
}