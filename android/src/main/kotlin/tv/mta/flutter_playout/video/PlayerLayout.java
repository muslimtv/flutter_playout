package tv.mta.flutter_playout.video;

import android.app.Activity;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.support.v4.media.MediaMetadataCompat;
import android.support.v4.media.session.MediaSessionCompat;
import android.support.v4.media.session.PlaybackStateCompat;
import android.util.Log;
import android.view.KeyEvent;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.core.app.NotificationCompat;

import com.google.android.exoplayer2.ExoPlaybackException;
import com.google.android.exoplayer2.ExoPlayerFactory;
import com.google.android.exoplayer2.Player;
import com.google.android.exoplayer2.SimpleExoPlayer;
import com.google.android.exoplayer2.analytics.AnalyticsListener;
import com.google.android.exoplayer2.source.MediaSource;
import com.google.android.exoplayer2.source.hls.HlsMediaSource;
import com.google.android.exoplayer2.ui.PlayerView;
import com.google.android.exoplayer2.upstream.DataSource;
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory;
import com.google.android.exoplayer2.util.Util;

import org.json.JSONObject;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.JSONMethodCodec;
import tv.mta.flutter_playout.FlutterAVPlayer;
import tv.mta.flutter_playout.MediaNotificationManagerService;
import tv.mta.flutter_playout.PlayerNotificationUtil;
import tv.mta.flutter_playout.PlayerState;
import tv.mta.flutter_playout.R;

public class PlayerLayout extends PlayerView implements FlutterAVPlayer, EventChannel.StreamHandler {
    private final String TAG = "PlayerLayout";

    public static SimpleExoPlayer activePlayer;

    private PlayerLayout instance;

    /**
     * Reference to the {@link SimpleExoPlayer}
     */
    SimpleExoPlayer mPlayerView;

    /**
     * The underlying {@link MediaSessionCompat}.
     */
    private MediaSessionCompat mMediaSessionCompat;

    /**
     * Playback Rate for the MediaPlayer is always 1.0.
     */
    private static final float PLAYBACK_RATE = 1.0f;

    /**
     * The notification channel id we'll send notifications too
     */
    public static final String mNotificationChannelId = "NotificationBarController";

    /**
     * The notification id.
     */
    private static final int NOTIFICATION_ID = 0;

    /**
     * An instance of Flutter event sink
     */
    private EventChannel.EventSink eventSink;

    /**
     * App main activity
     */
    private Activity activity;

    boolean isBound = true;

    private int viewId;

    /**
     * Context
     */
    private Context context;

    private BinaryMessenger messenger;

    private EventChannel eventChannel;

    private String url = "";

    private String title = "";

    private String subtitle = "";

    private boolean autoPlay = false;

    private long mediaDuration = 0L;

    public PlayerLayout(@NonNull Context context, Activity activity, BinaryMessenger messenger, int id, Object arguments) {
        super(context);

        this.activity = activity;

        this.context = context;

        this.messenger = messenger;

        this.viewId = id;

        try {

            JSONObject args = (JSONObject) arguments;

            try {
                this.url = args.getString("url");
            } catch (Exception e) { /* ignore */ }

            try {
                this.title = args.getString("title");
            } catch (Exception e) { /* ignore */ }

            try {
                this.subtitle = args.getString("subtitle");
            } catch (Exception e) { /* ignore */ }

            try {
                this.autoPlay = args.getBoolean("autoPlay");
            } catch (Exception e) { /* ignore */ }

            initPlayer();

        } catch (Exception e) { /* ignore */ }

        instance = this;

        /* release previous instance */
        if (activePlayer != null) {

            activePlayer.release();
        }

        activePlayer = mPlayerView;
    }

    @Override
    public void onListen(Object o, EventChannel.EventSink eventSink) {
        this.eventSink = eventSink;
    }

    @Override
    public void onCancel(Object o) {
        this.eventSink = null;
    }

    private void initPlayer() {

        mPlayerView = ExoPlayerFactory.newSimpleInstance(context);

        mPlayerView.setPlayWhenReady(this.autoPlay);

        mPlayerView.addAnalyticsListener(new PlayerAnalyticsEventsListener());

        listenForPlayerTimeChange();

        this.setPlayer(mPlayerView);

        eventChannel = new EventChannel(
                messenger,
                "tv.mta/NativeVideoPlayerEventChannel_" + this.viewId,
                JSONMethodCodec.INSTANCE);

        eventChannel.setStreamHandler(this);

        /* Produces DataSource instances through which media data is loaded. */
        DataSource.Factory dataSourceFactory = new DefaultDataSourceFactory(context,
                Util.getUserAgent(context, "flutter_playout"));

        /* This is the MediaSource representing the media to be played. */
        MediaSource videoSource = new HlsMediaSource.Factory(dataSourceFactory)
                .createMediaSource(Uri.parse(this.url));

        mPlayerView.prepare(videoSource);

        setupMediaSession();

        doBindMediaNotificationManagerService();
    }

    private void setupMediaSession() {

        ComponentName receiver = new ComponentName(context.getPackageName(),
                RemoteReceiver.class.getName());

        /* Create a new MediaSession */
        mMediaSessionCompat = new MediaSessionCompat(context,
                PlayerLayout.class.getSimpleName(), receiver, null);

        mMediaSessionCompat.setFlags(MediaSessionCompat.FLAG_HANDLES_TRANSPORT_CONTROLS
                | MediaSessionCompat.FLAG_HANDLES_MEDIA_BUTTONS);

        mMediaSessionCompat.setCallback(new MediaSessionCallback());

        mMediaSessionCompat.setActive(true);

        setAudioMetadata();

        updatePlaybackState(PlayerState.PLAYING);
    }

    private void setAudioMetadata() {

        MediaMetadataCompat metadata = new MediaMetadataCompat.Builder()
                .putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_TITLE, title)
                .putString(MediaMetadataCompat.METADATA_KEY_TITLE, title)
                .putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_SUBTITLE, subtitle)
                .build();

        mMediaSessionCompat.setMetadata(metadata);
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
                playbackStateCompat = PlaybackStateCompat.STATE_STOPPED;
                break;
        }
        newPlaybackState.setState(playbackStateCompat, (long) mPlayerView.getCurrentPosition(), PLAYBACK_RATE);

        mMediaSessionCompat.setPlaybackState(newPlaybackState.build());

        updateNotification(capabilities);
    }

    private @PlaybackStateCompat.Actions long getCapabilities(PlayerState playerState) {
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
                capabilities |= PlaybackStateCompat.ACTION_PLAY;
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

        notificationBuilder = addActions(notificationBuilder, capabilities);

        NotificationManager notificationManager = (NotificationManager)
                context.getSystemService(Context.NOTIFICATION_SERVICE);

        notificationManager.notify(NOTIFICATION_ID, notificationBuilder.build());
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private void createNotificationChannel(){

        NotificationManager notificationManager = (NotificationManager) context.getSystemService(context.NOTIFICATION_SERVICE);

        String id = mNotificationChannelId;

        CharSequence channelNameDisplayedToUser = "Notification Bar Controls";

        int importance = NotificationManager.IMPORTANCE_LOW;

        NotificationChannel newChannel = new NotificationChannel(id,channelNameDisplayedToUser,importance);

        newChannel.setDescription("All notifications");

        newChannel.setShowBadge(false);

        newChannel.setLockscreenVisibility(Notification.VISIBILITY_PUBLIC);

        notificationManager.createNotificationChannel(newChannel);
    }

    private NotificationCompat.Builder addActions(NotificationCompat.Builder notification,
                                                  long capabilities) {

        if ((capabilities & PlaybackStateCompat.ACTION_PAUSE) != 0) {
            notification.addAction(R.drawable.ic_pause, "Pause",
                    PlayerNotificationUtil.getActionIntent(context, KeyEvent.KEYCODE_MEDIA_PAUSE));
        }
        if ((capabilities & PlaybackStateCompat.ACTION_PLAY) != 0) {
            notification.addAction(R.drawable.ic_play, "Play",
                    PlayerNotificationUtil.getActionIntent(context, KeyEvent.KEYCODE_MEDIA_PLAY));
        }
        return notification;
    }

    private void cleanPlayerNotification() {
        NotificationManager notificationManager = (NotificationManager)
                getContext().getSystemService(Context.NOTIFICATION_SERVICE);

        notificationManager.cancel(NOTIFICATION_ID);
    }

    /**
     * Whether we have bound to a {@link MediaNotificationManagerService}.
     */
    private boolean mIsBoundMediaNotificationManagerService;

    /**
     * The {@link MediaNotificationManagerService} we are bound to.
     */
    private MediaNotificationManagerService mMediaNotificationManagerService;

    /**
     * The {@link ServiceConnection} serves as glue between this activity and the {@link MediaNotificationManagerService}.
     */
    private ServiceConnection mMediaNotificationManagerServiceConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName componentName, IBinder service) {

            mMediaNotificationManagerService = ((MediaNotificationManagerService.MediaNotificationManagerServiceBinder) service)
                    .getService();

            mMediaNotificationManagerService.setActivePlayer(instance);
        }

        @Override
        public void onServiceDisconnected(ComponentName componentName) {

            mMediaNotificationManagerService = null;
        }
    };

    private void doBindMediaNotificationManagerService() {

        Intent service = new Intent(this.context,
                MediaNotificationManagerService.class);

        this.context.bindService(service, mMediaNotificationManagerServiceConnection, Context.BIND_AUTO_CREATE);

        mIsBoundMediaNotificationManagerService = true;

        this.context.startService(service);
    }

    private void doUnbindMediaNotificationManagerService() {

        if (mIsBoundMediaNotificationManagerService) {

            this.context.unbindService(mMediaNotificationManagerServiceConnection);

            mIsBoundMediaNotificationManagerService = false;
        }
    }

    /**
     * A {@link android.support.v4.media.session.MediaSessionCompat.Callback} implementation for MediaPlayer.
     */
    private final class MediaSessionCallback extends MediaSessionCompat.Callback {

        @Override
        public void onPause() {
            pause();
        }

        @Override
        public void onPlay() {
            play();
        }

        @Override
        public void onSeekTo(long pos) {
            mPlayerView.seekTo(pos);
        }

        @Override
        public void onStop() {
            pause();
        }
    }

    public void pause() {
        if (mPlayerView != null) {
            mPlayerView.setPlayWhenReady(false);
        }
    }

    public void play() {
        if (mPlayerView != null) {
            mPlayerView.setPlayWhenReady(true);
        }
    }

    /**
     * Player events listener for analytics
     */
    class PlayerAnalyticsEventsListener implements AnalyticsListener {

        /* used with onSeek callback to Flutter code */
        long beforeSeek = 0;

        @Override
        public void onSeekProcessed(EventTime eventTime) {

            try {

                JSONObject message = new JSONObject();

                message.put("name", "onSeek");

                message.put("position", beforeSeek);

                message.put("offset", eventTime.currentPlaybackPositionMs / 1000);

                Log.d(TAG, "onSeek: [position=" + beforeSeek + "] [offset=" +
                        eventTime.currentPlaybackPositionMs / 1000 + "]");
                eventSink.success(message);

            } catch (Exception e) {
                Log.e(TAG, "onSeek: ", e);
            }
        }

        @Override
        public void onSeekStarted(EventTime eventTime) {

            beforeSeek = eventTime.currentPlaybackPositionMs / 1000;
        }

        @Override
        public void onPlayerError(EventTime eventTime, ExoPlaybackException error) {

            try {

                final String errorMessage = "ExoPlaybackException Type [" + error.type + "] " +
                        error.getSourceException().getCause().getMessage();

                JSONObject message = new JSONObject();

                message.put("name", "onError");

                message.put("error", errorMessage);

                Log.d(TAG, "onError: [errorMessage=" + errorMessage + "]");
                eventSink.success(message);

            } catch (Exception e) {
                Log.e(TAG, "onError: ", e);
            }
        }

        @Override
        public void onPlayerStateChanged(EventTime eventTime, boolean playWhenReady, int playbackState) {

            if (playbackState == Player.STATE_READY) {

                if (playWhenReady) {

                    try {

                        updatePlaybackState(PlayerState.PLAYING);

                        JSONObject message = new JSONObject();

                        message.put("name", "onPlay");

                        Log.d(TAG, "onPlay: []");
                        eventSink.success(message);

                    } catch (Exception e) {
                        Log.e(TAG, "onPlay: ", e);
                    }

                } else {

                    try {

                        updatePlaybackState(PlayerState.PAUSED);

                        JSONObject message = new JSONObject();

                        message.put("name", "onPause");

                        Log.d(TAG, "onPause: []");
                        eventSink.success(message);

                    } catch (Exception e) {
                        Log.e(TAG, "onPause: ", e);
                    }

                }

                onDuration();

            } else if (playbackState == Player.STATE_ENDED) {

                try {

                    updatePlaybackState(PlayerState.COMPLETE);

                    JSONObject message = new JSONObject();

                    message.put("name", "onComplete");

                    Log.d(TAG, "onComplete: []");
                    eventSink.success(message);

                } catch (Exception e) {
                    Log.e(TAG, "onComplete: ", e);
                }

            }
        }
    }

    /* onTime listener */
    private void listenForPlayerTimeChange() {

        final Handler handler = new Handler();

        final Runnable runnable = new Runnable() {
            @Override
            public void run() {

                try {

                    if (mPlayerView.isPlaying()) {

                        JSONObject message = new JSONObject();

                        message.put("name", "onTime");

                        message.put("time", mPlayerView.getCurrentPosition() / 1000);

                        Log.d(TAG, "onTime: [time=" + mPlayerView.getCurrentPosition() / 1000 + "]");
                        eventSink.success(message);
                    }

                } catch (Exception e) {
                    Log.e(TAG, "onTime: ", e);
                }

                onDuration();

                if (isBound) {

                    /* keep running if player view is still active */
                    handler.postDelayed(this, 1000);
                }
            }
        };

        handler.post(runnable);
    }

    public void onMediaChanged(Object arguments) {

        try {

            try {

                JSONObject args = (JSONObject) arguments;

                this.url = args.getString("url");

                this.title = args.getString("title");

                this.subtitle = args.getString("description");

                /* Produces DataSource instances through which media data is loaded. */
                DataSource.Factory dataSourceFactory = new DefaultDataSourceFactory(context,
                        Util.getUserAgent(context, "flutter_playout"));

                /* This is the new MediaSource representing the media to be played. */
                MediaSource videoSource = new HlsMediaSource.Factory(dataSourceFactory)
                        .createMediaSource(Uri.parse(this.url));

                mPlayerView.prepare(videoSource);

            } catch (Exception e) { /* ignore */ }

        } catch (Exception e) { /* ignore */ }
    }

    void onDuration() {

        try {

            long newDuration = mPlayerView.getDuration();

            if (newDuration != mediaDuration && eventSink != null) {

                mediaDuration = newDuration;

                JSONObject message = new JSONObject();

                message.put("name", "onDuration");

                message.put("duration", mediaDuration);

                Log.d(TAG, "onDuration: [duration=" + mediaDuration + "]");
                eventSink.success(message);
            }

        } catch (Exception e) {
            Log.e(TAG, "onDuration: " + e.getMessage(), e);
        }
    }

    @Override
    public void onDestroy() {

        try {

            isBound = false;

            /* let Player know that the app is being destroyed */
            mPlayerView.release();

            doUnbindMediaNotificationManagerService();

            cleanPlayerNotification();

            activePlayer = null;

        } catch (Exception e) { /* ignore */ }
    }
}