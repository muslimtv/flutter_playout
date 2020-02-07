package tv.mta.flutter_playout.audio;

import android.app.Activity;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.ComponentName;
import android.content.Context;
import android.media.MediaPlayer;
import android.os.Binder;
import android.os.Build;
import android.os.Handler;
import android.os.Message;
import android.support.v4.media.MediaMetadataCompat;
import android.support.v4.media.session.MediaSessionCompat;
import android.support.v4.media.session.PlaybackStateCompat;
import android.text.TextUtils;
import android.util.Log;
import android.view.KeyEvent;

import androidx.annotation.RequiresApi;
import androidx.core.app.NotificationCompat;

import java.io.IOException;

import tv.mta.flutter_playout.FlutterAVPlayer;
import tv.mta.flutter_playout.PlayerNotificationUtil;
import tv.mta.flutter_playout.PlayerState;
import tv.mta.flutter_playout.R;

public class AudioServiceBinder
        extends Binder
        implements FlutterAVPlayer, MediaPlayer.OnPreparedListener,
        MediaPlayer.OnCompletionListener, MediaPlayer.OnErrorListener {

    private static final String TAG = "AudioServiceBinder";

    /**
     * The notification channel id we'll send notifications too
     */
    private static final String mNotificationChannelId = "NotificationBarController";
    /**
     * Playback Rate for the MediaPlayer is always 1.0.
     */
    private static final float PLAYBACK_RATE = 1.0f;
    /**
     * The notification id.
     */
    private static final int NOTIFICATION_ID = 0;
    static AudioServiceBinder service;
    // This is the message signal that inform audio progress updater to update audio progress.
    final int UPDATE_AUDIO_PROGRESS_BAR = 1;
    final int UPDATE_PLAYER_STATE_TO_PAUSE = 2;
    final int UPDATE_PLAYER_STATE_TO_PLAY = 3;
    final int UPDATE_PLAYER_STATE_TO_COMPLETE = 4;
    final int UPDATE_AUDIO_DURATION = 5;
    final int UPDATE_PLAYER_STATE_TO_ERROR = 6;
    private boolean isPlayerReady = false;
    private boolean isBound = true;

    private boolean isMediaChanging = false;

    /**
     * Whether the {@link MediaPlayer} broadcasted an error.
     */
    private boolean mReceivedError;

    private String audioFileUrl = "";

    private String title;

    private String subtitle;

    private MediaPlayer audioPlayer = null;

    private int startPositionInMills = 0;

    // This Handler object is a reference to the caller activity's Handler.
    // In the caller activity's handler, it will update the audio play progress.
    private Handler audioProgressUpdateHandler;

    /**
     * The underlying {@link MediaSessionCompat}.
     */
    private MediaSessionCompat mMediaSessionCompat;

    private Context context;

    private Activity activity;

    MediaPlayer getAudioPlayer() {
        return audioPlayer;
    }

    String getAudioFileUrl() {
        return audioFileUrl;
    }

    void setAudioFileUrl(String audioFileUrl) {
        this.audioFileUrl = audioFileUrl;
    }

    void setTitle(String title) {
        this.title = title;
    }

    void setSubtitle(String subtitle) {
        this.subtitle = subtitle;
    }

    void setAudioProgressUpdateHandler(Handler audioProgressUpdateHandler) {
        this.audioProgressUpdateHandler = audioProgressUpdateHandler;
    }

    private Context getContext() {
        return context;
    }

    void setContext(Context context) {
        this.context = context;
    }

    void setActivity(Activity activity) {
        this.activity = activity;
    }

    boolean isMediaChanging() {
        return isMediaChanging;
    }

    void setMediaChanging(boolean mediaChanging) {
        isMediaChanging = mediaChanging;
    }

    private void setAudioMetadata() {
        MediaMetadataCompat metadata = new MediaMetadataCompat.Builder()
                .putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_TITLE, title)
                .putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_SUBTITLE, subtitle)
                .build();

        mMediaSessionCompat.setMetadata(metadata);
    }

    void startAudio(int startPositionInMills) {

        this.startPositionInMills = startPositionInMills;

        initAudioPlayer();

        if (audioPlayer != null && mMediaSessionCompat != null && mMediaSessionCompat.isActive()) {

            updatePlaybackState(PlayerState.PLAYING);

            // Create update audio player state message.
            Message updateAudioProgressMsg = new Message();

            updateAudioProgressMsg.what = UPDATE_PLAYER_STATE_TO_PLAY;

            // Send the message to caller activity's update audio Handler object.
            audioProgressUpdateHandler.sendMessage(updateAudioProgressMsg);
        }

        service = this;
    }

    void seekAudio(int position) {

        if (isPlayerReady) {

            audioPlayer.seekTo(position * 1000);
        }
    }

    void pauseAudio() {

        if (audioPlayer != null) {

            if (audioPlayer.isPlaying()) {

                audioPlayer.pause();
            }

            updatePlaybackState(PlayerState.PAUSED);

            // Create update audio player state message.
            Message updateAudioProgressMsg = new Message();

            updateAudioProgressMsg.what = UPDATE_PLAYER_STATE_TO_PAUSE;

            // Send the message to caller activity's update audio Handler object.
            audioProgressUpdateHandler.sendMessage(updateAudioProgressMsg);
        }
    }

    void reset() {

        if (audioPlayer != null) {

            if (audioPlayer.isPlaying()) {

                audioPlayer.stop();
            }

            audioPlayer.reset();

            audioPlayer = null;

            updatePlaybackState(PlayerState.COMPLETE);
        }
    }

    void cleanPlayerNotification() {
        NotificationManager notificationManager = (NotificationManager)
                getContext().getSystemService(Context.NOTIFICATION_SERVICE);

        if (notificationManager != null) {

            notificationManager.cancel(NOTIFICATION_ID);
        }
    }

    private void initAudioPlayer() {

        try {

            if (audioPlayer == null) {

                audioPlayer = new MediaPlayer();

                if (!TextUtils.isEmpty(getAudioFileUrl())) {

                    audioPlayer.setDataSource(getAudioFileUrl());
                }

                audioPlayer.setOnPreparedListener(this);

                audioPlayer.setOnCompletionListener(this);

                audioPlayer.setOnErrorListener(this);

                audioPlayer.prepareAsync();
            }

            else {

                audioPlayer.start();
            }

        } catch (IOException ex) {
            mReceivedError = true;
        }
    }

    @Override
    public void onDestroy() {

        isBound = false;

        try {

            cleanPlayerNotification();

            if (audioPlayer != null) {

                if (audioPlayer.isPlaying()) {

                    audioPlayer.stop();
                }

                audioPlayer.reset();

                audioPlayer.release();

                audioPlayer = null;
            }

        } catch (Exception e) { /* ignore */ }
    }

    int getCurrentAudioPosition() {
        int ret = 0;

        if (audioPlayer != null) {

            ret = audioPlayer.getCurrentPosition();
        }

        return ret;
    }

    @Override
    public void onPrepared(MediaPlayer mp) {

        isPlayerReady = true;

        isBound = true;

        setMediaChanging(false);

        if (startPositionInMills > 0) {
            mp.seekTo(startPositionInMills);
        }

        mp.start();

        ComponentName receiver = new ComponentName(context.getPackageName(),
                RemoteReceiver.class.getName());

        /* Create a new MediaSession */
        mMediaSessionCompat = new MediaSessionCompat(context,
                AudioServiceBinder.class.getSimpleName(), receiver, null);

        mMediaSessionCompat.setFlags(MediaSessionCompat.FLAG_HANDLES_TRANSPORT_CONTROLS
                | MediaSessionCompat.FLAG_HANDLES_MEDIA_BUTTONS);

        mMediaSessionCompat.setCallback(new MediaSessionCallback(audioPlayer));

        mMediaSessionCompat.setActive(true);

        setAudioMetadata();

        updatePlaybackState(PlayerState.PLAYING);

        /* This thread object will send update audio progress message to caller activity every 1 second */
        Thread updateAudioProgressThread = new Thread() {

            @Override
            public void run() {

                while (isBound) {

                    try {

                        if (audioPlayer != null && audioPlayer.isPlaying()) {

                            // Create update audio progress message.
                            Message updateAudioProgressMsg = new Message();

                            updateAudioProgressMsg.what = UPDATE_AUDIO_PROGRESS_BAR;

                            // Send the message to caller activity's update audio progressbar Handler object.
                            audioProgressUpdateHandler.sendMessage(updateAudioProgressMsg);

                            try {

                                Thread.sleep(1000);

                            } catch (InterruptedException ex) { /* ignore */ }

                        } else {

                            try {

                                Thread.sleep(100);

                            } catch (InterruptedException ex) { /* ignore */ }
                        }

                        // Create update audio duration message.
                        Message updateAudioDurationMsg = new Message();

                        updateAudioDurationMsg.what = UPDATE_AUDIO_DURATION;

                        // Send the message to caller activity's update audio progressbar Handler object.
                        audioProgressUpdateHandler.sendMessage(updateAudioDurationMsg);

                    } catch (Exception e) {

                        Log.e(TAG, "onPrepared:updateAudioProgressThread: ", e);
                    }
                }
            }
        };

        updateAudioProgressThread.start();
    }

    @Override
    public void onCompletion(MediaPlayer mp) {

        if (audioPlayer != null) {

            audioPlayer.pause();

            updatePlaybackState(PlayerState.PAUSED);

            // Create update audio player state message.
            Message updateAudioProgressMsg = new Message();

            updateAudioProgressMsg.what = UPDATE_PLAYER_STATE_TO_COMPLETE;

            // Send the message to caller activity's update audio Handler object.
            audioProgressUpdateHandler.sendMessage(updateAudioProgressMsg);
        }
    }

    @Override
    public boolean onError(MediaPlayer mp, int what, int extra) {

        updatePlaybackState(PlayerState.PAUSED);

        // Create update audio player state message.
        Message updateAudioPlayerStateMessage = new Message();

        updateAudioPlayerStateMessage.what = UPDATE_PLAYER_STATE_TO_ERROR;

        Log.e("AudioServiceBinder", "onPlayerError: [what=" + what + "] [extra=" + extra + "]", null);
        String errorMessage = "";
        switch (what) {
            case MediaPlayer.MEDIA_ERROR_IO:
                errorMessage = "MEDIA_ERROR_IO: File or network related operation error";
                break;
            case MediaPlayer.MEDIA_ERROR_MALFORMED:
                errorMessage = "MEDIA_ERROR_MALFORMED: Bitstream is not conforming to the related" +
                        " coding standard or file spec";
                break;
            case MediaPlayer.MEDIA_ERROR_NOT_VALID_FOR_PROGRESSIVE_PLAYBACK:
                errorMessage = "MEDIA_ERROR_NOT_VALID_FOR_PROGRESSIVE_PLAYBACK:  The video is str" +
                        "eamed and its container is not valid for progressive playback i.e the vi" +
                        "deo's index (e.g moov atom) is not at the start of the file";
                break;
            case MediaPlayer.MEDIA_ERROR_SERVER_DIED:
                errorMessage = "MEDIA_ERROR_SERVER_DIED: Media server died";
                break;
            case MediaPlayer.MEDIA_ERROR_TIMED_OUT:
                errorMessage = "MEDIA_ERROR_TIMED_OUT: Some operation takes too long to complete," +
                        " usually more than 3-5 seconds";
                break;
            case MediaPlayer.MEDIA_ERROR_UNKNOWN:
                errorMessage = "MEDIA_ERROR_UNKNOWN: Unspecified media player error";
                break;
            case MediaPlayer.MEDIA_ERROR_UNSUPPORTED:
                errorMessage = "MEDIA_ERROR_UNSUPPORTED: Bitstream is conforming to the related c" +
                        "oding standard or file spec, but the media framework does not support th" +
                        "e feature";
                break;
            default:
                errorMessage = "MEDIA_ERROR_UNKNOWN: Unspecified media player error";
                break;
        }
        updateAudioPlayerStateMessage.obj = errorMessage;

        // Send the message to caller activity's update audio Handler object.
        audioProgressUpdateHandler.sendMessage(updateAudioPlayerStateMessage);

        return false;
    }

    private PlaybackStateCompat.Builder getPlaybackStateBuilder() {

        PlaybackStateCompat playbackState = mMediaSessionCompat.getController().getPlaybackState();

        return playbackState == null
                ? new PlaybackStateCompat.Builder()
                : new PlaybackStateCompat.Builder(playbackState);
    }

    private void updatePlaybackState(PlayerState playerState) {

        if (mMediaSessionCompat == null) return;

        PlaybackStateCompat.Builder newPlaybackState = getPlaybackStateBuilder();

        long capabilities = getCapabilities(playerState);

        newPlaybackState.setActions(capabilities);

        int playbackStateCompat = PlaybackStateCompat.STATE_NONE;

        switch (playerState) {
            case PLAYING:
                playbackStateCompat = PlaybackStateCompat.STATE_PLAYING;
                break;
            case PAUSED:
                playbackStateCompat = PlaybackStateCompat.STATE_PAUSED;
                break;
            case BUFFERING:
                playbackStateCompat = PlaybackStateCompat.STATE_BUFFERING;
                break;
            case IDLE:
                if (mReceivedError) {
                    playbackStateCompat = PlaybackStateCompat.STATE_ERROR;
                } else {
                    playbackStateCompat = PlaybackStateCompat.STATE_STOPPED;
                }
                break;
        }

        if (audioPlayer != null) {
            newPlaybackState.setState(playbackStateCompat,
                    (long) audioPlayer.getCurrentPosition(), PLAYBACK_RATE);
        }

        mMediaSessionCompat.setPlaybackState(newPlaybackState.build());

        updateNotification(capabilities);
    }

    private @PlaybackStateCompat.Actions
    long getCapabilities(PlayerState playerState) {
        long capabilities = 0;

        switch (playerState) {
            case PLAYING:
                capabilities |= PlaybackStateCompat.ACTION_PAUSE
                        | PlaybackStateCompat.ACTION_STOP;
                break;
            case PAUSED:
                capabilities |= PlaybackStateCompat.ACTION_PLAY
                        | PlaybackStateCompat.ACTION_STOP;
                break;
            case BUFFERING:
                capabilities |= PlaybackStateCompat.ACTION_PAUSE
                        | PlaybackStateCompat.ACTION_STOP;
                break;
            case IDLE:
                if (!mReceivedError) {
                    capabilities |= PlaybackStateCompat.ACTION_PLAY;
                }
                break;
        }

        return capabilities;
    }

    private void updateNotification(long capabilities) {

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

            createNotificationChannel();
        }

        NotificationCompat.Builder notificationBuilder = PlayerNotificationUtil.from(
                activity, context, mMediaSessionCompat, mNotificationChannelId);

        if ((capabilities & PlaybackStateCompat.ACTION_PAUSE) != 0) {
            notificationBuilder.addAction(R.drawable.ic_pause, "Pause",
                    PlayerNotificationUtil.getActionIntent(context, KeyEvent.KEYCODE_MEDIA_PAUSE));
        }

        if ((capabilities & PlaybackStateCompat.ACTION_PLAY) != 0) {
            notificationBuilder.addAction(R.drawable.ic_play, "Play",
                    PlayerNotificationUtil.getActionIntent(context, KeyEvent.KEYCODE_MEDIA_PLAY));
        }

        NotificationManager notificationManager = (NotificationManager)
                context.getSystemService(Context.NOTIFICATION_SERVICE);

        if (notificationManager != null) {

            notificationManager.notify(NOTIFICATION_ID, notificationBuilder.build());
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private void createNotificationChannel() {

        NotificationManager notificationManager = (NotificationManager)
                context.getSystemService(Context.NOTIFICATION_SERVICE);

        CharSequence channelNameDisplayedToUser = "Notification Bar Controls";

        int importance = NotificationManager.IMPORTANCE_LOW;

        NotificationChannel newChannel = new NotificationChannel(
                mNotificationChannelId, channelNameDisplayedToUser, importance);

        newChannel.setDescription("All notifications");

        newChannel.setShowBadge(false);

        newChannel.setLockscreenVisibility(Notification.VISIBILITY_PUBLIC);

        if (notificationManager != null) {

            notificationManager.createNotificationChannel(newChannel);
        }
    }

    /**
     * A {@link android.support.v4.media.session.MediaSessionCompat.Callback} implementation for MediaPlayer.
     */
    private final class MediaSessionCallback extends MediaSessionCompat.Callback {

        MediaSessionCallback(MediaPlayer player) {
            audioPlayer = player;
        }

        @Override
        public void onPause() {
            audioPlayer.pause();
        }

        @Override
        public void onPlay() {
            audioPlayer.start();
        }

        @Override
        public void onSeekTo(long pos) {
            audioPlayer.seekTo((int) pos);
        }

        @Override
        public void onStop() {
            audioPlayer.stop();
        }
    }
}