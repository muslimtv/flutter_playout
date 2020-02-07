package tv.mta.flutter_playout.audio;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Handler;
import android.os.IBinder;
import android.os.Message;
import android.util.Log;

import org.jetbrains.annotations.NotNull;
import org.json.JSONObject;

import java.lang.ref.WeakReference;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.JSONMethodCodec;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.view.FlutterNativeView;
import tv.mta.flutter_playout.MediaNotificationManagerService;

public class AudioPlayer implements MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private final String TAG = "AudioPlayer";

    private AudioServiceBinder audioServiceBinder = null;

    private Handler audioProgressUpdateHandler;

    private EventChannel.EventSink eventSink;

    private Activity activity;

    private Context context;

    private String audioURL;

    private String title;

    private String subtitle;

    private int startPositionInMills;

    private int mediaDuration = 0;
    /**
     * Whether we have bound to a {@link MediaNotificationManagerService}.
     */
    private boolean mIsBoundMediaNotificationManagerService;
    /**
     * The {@link MediaNotificationManagerService} we are bound to.
     */
    private MediaNotificationManagerService mMediaNotificationManagerService;
    /**
     * The {@link ServiceConnection} serves as glue between this activity and the
     * {@link MediaNotificationManagerService}.
     */
    private ServiceConnection mMediaNotificationManagerServiceConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName componentName, IBinder service) {

            mMediaNotificationManagerService =
                    ((MediaNotificationManagerService.MediaNotificationManagerServiceBinder) service)
                    .getService();

            mMediaNotificationManagerService.setActivePlayer(audioServiceBinder);
        }

        @Override
        public void onServiceDisconnected(ComponentName componentName) {

            mMediaNotificationManagerService = null;
        }
    };
    /* This service connection object is the bridge between activity and background service. */
    private ServiceConnection serviceConnection = new ServiceConnection() {

        @Override
        public void onServiceConnected(ComponentName componentName, IBinder iBinder) {

            /* Cast and assign background service's onBind method returned iBinder object */
            audioServiceBinder = (AudioServiceBinder) iBinder;

            audioServiceBinder.setActivity(activity);

            audioServiceBinder.setContext(context);

            audioServiceBinder.setAudioFileUrl(audioURL);

            audioServiceBinder.setTitle(title);

            audioServiceBinder.setSubtitle(subtitle);

            audioServiceBinder.setAudioProgressUpdateHandler(audioProgressUpdateHandler);

            audioServiceBinder.startAudio(startPositionInMills);

            doBindMediaNotificationManagerService();
        }

        @Override
        public void onServiceDisconnected(ComponentName componentName) {

        }
    };

    private AudioPlayer(BinaryMessenger messenger, Context context) {

        this.context = context;

        this.audioProgressUpdateHandler = new IncomingMessageHandler(this);

        new MethodChannel(messenger, "tv.mta/NativeAudioChannel")
                .setMethodCallHandler(this);

        new EventChannel(messenger, "tv.mta/NativeAudioEventChannel", JSONMethodCodec.INSTANCE)
                .setStreamHandler(this);
    }

    public static void registerWith(PluginRegistry.Registrar registrar) {

        final AudioPlayer plugin = new AudioPlayer(registrar.messenger(), registrar.activeContext());

        plugin.activity = registrar.activity();

        registrar.addViewDestroyListener(new PluginRegistry.ViewDestroyListener() {
            @Override
            public boolean onViewDestroy(FlutterNativeView view) {
                plugin.onDestroy();
                return false;
            }
        });
    }

    @Override
    public void onListen(Object o, EventChannel.EventSink eventSink) {
        this.eventSink = eventSink;
    }

    @Override
    public void onCancel(Object o) {
        this.eventSink = null;
    }

    private void doBindMediaNotificationManagerService() {

        Intent service = new Intent(this.context,
                MediaNotificationManagerService.class);

        this.context.bindService(service, mMediaNotificationManagerServiceConnection,
                Context.BIND_AUTO_CREATE);

        mIsBoundMediaNotificationManagerService = true;

        this.context.startService(service);
    }

    private void doUnbindMediaNotificationManagerService() {

        if (mIsBoundMediaNotificationManagerService) {

            this.context.unbindService(mMediaNotificationManagerServiceConnection);

            mIsBoundMediaNotificationManagerService = false;
        }
    }

    private void play(Object arguments) {

        java.util.HashMap<String, Object> args = (java.util.HashMap<String, Object>) arguments;

        String newUrl = (String) args.get("url");

        boolean mediaChanged = true;

        if (this.audioURL != null) {

            mediaChanged = !this.audioURL.equals(newUrl);
        }

        this.audioURL = newUrl;

        this.title = (String) args.get("title");

        this.subtitle = (String) args.get("subtitle");

        try {

            this.startPositionInMills = (int) args.get("position");

        } catch (Exception e) { /* ignore */ }

        if (audioServiceBinder != null) {

            if (mediaChanged) {

                try {

                    audioServiceBinder.reset();

                } catch (Exception e) { /* ignore */}

                audioServiceBinder.setMediaChanging(true);
            }

            audioServiceBinder.setAudioFileUrl(this.audioURL);

            audioServiceBinder.setTitle(this.title);

            audioServiceBinder.setSubtitle(this.subtitle);

            audioServiceBinder.startAudio(startPositionInMills);

        } else {

            bindAudioService();
        }

        notifyDartOnPlay();
    }

    private void pause() {

        if (audioServiceBinder != null) {

            audioServiceBinder.pauseAudio();
        }

        notifyDartOnPause();
    }

    private void reset() {

        if (audioServiceBinder != null) {

            audioServiceBinder.reset();

            audioServiceBinder.cleanPlayerNotification();

            audioServiceBinder = null;
        }
    }

    private void notifyDartOnPlay() {

        try {

            JSONObject message = new JSONObject();

            message.put("name", "onPlay");

            eventSink.success(message);

        } catch (Exception e) {

            Log.e(TAG, "notifyDartOnPlay: ", e);
        }
    }

    private void notifyDartOnPause() {

        try {

            JSONObject message = new JSONObject();

            message.put("name", "onPause");

            eventSink.success(message);

        } catch (Exception e) {

            Log.e(TAG, "notifyDartOnPause: ", e);
        }
    }

    private void notifyDartOnComplete() {

        try {

            JSONObject message = new JSONObject();

            message.put("name", "onComplete");

            eventSink.success(message);

        } catch (Exception e) {

            Log.e(TAG, "notifyDartOnComplete: ", e);
        }
    }

    private void notifyDartOnError(String errorMessage) {

        try {

            JSONObject message = new JSONObject();

            message.put("name", "onError");

            message.put("error", errorMessage);

            eventSink.success(message);

        } catch (Exception e) {

            Log.e(TAG, "notifyDartOnError: ", e);
        }
    }

    private void seekTo(Object arguments) {

        try {

            java.util.HashMap<String, Double> args = (java.util.HashMap<String, Double>) arguments;

            Double position = args.get("second");

            if (audioServiceBinder != null && position != null) {

                audioServiceBinder.seekAudio(position.intValue());
            }

        } catch (Exception e) {

            notifyDartOnError(e.getMessage());
        }
    }

    private void onDuration() {

        try {

            if (audioServiceBinder != null &&
                    audioServiceBinder.getAudioPlayer() != null &&
                    !audioServiceBinder.isMediaChanging()) {

                int newDuration = audioServiceBinder.getAudioPlayer().getDuration();

                if (newDuration != mediaDuration) {

                    mediaDuration = newDuration;

                    JSONObject message = new JSONObject();

                    message.put("name", "onDuration");

                    message.put("duration", mediaDuration);

                    eventSink.success(message);
                }
            }

        } catch (Exception e) {

            Log.e(TAG, "onDuration: ", e);
        }
    }

    /**
     * Bind background service with caller activity. Then this activity can use
     * background service's AudioServiceBinder instance to invoke related methods.
     */
    private void bindAudioService() {

        if (audioServiceBinder == null) {

            Intent intent = new Intent(this.context, AudioService.class);

            this.context.bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE);
        }
    }

    /**
     * Unbound background audio service with caller activity.
     */
    private void unBoundAudioService() {

        if (audioServiceBinder != null) {

            this.context.unbindService(serviceConnection);

            reset();
        }
    }

    @Override
    public void onMethodCall(MethodCall call, @NotNull MethodChannel.Result result) {

        switch (call.method) {
            case "play": {
                play(call.arguments);
                result.success(true);
                break;
            }
            case "pause": {
                pause();
                result.success(true);
                break;
            }
            case "reset": {
                reset();
                result.success(true);
                break;
            }
            case "seekTo": {
                seekTo(call.arguments);
                result.success(true);
                break;
            }
            case "dispose": {
                onDestroy();
                result.success(true);
                break;
            }
            default:
                result.notImplemented();
        }
    }

    private void onDestroy() {

        try {

            unBoundAudioService();

            doUnbindMediaNotificationManagerService();

            /* reset media duration */
            mediaDuration = 0;

        } catch (Exception e) { /* ignore */ }
    }

    /* handles messages coming back from AudioServiceBinder */
    static class IncomingMessageHandler extends Handler {

        private final WeakReference<AudioPlayer> mService;

        IncomingMessageHandler(AudioPlayer service) {
            mService = new WeakReference<>(service);
        }

        @Override
        public void handleMessage(Message msg) {

            AudioPlayer service = mService.get();

            if (service != null && service.audioServiceBinder != null) {

                /* The update process message is sent from AudioServiceBinder class's thread object */
                if (msg.what == service.audioServiceBinder.UPDATE_AUDIO_PROGRESS_BAR) {

                    try {

                        int position = service.audioServiceBinder.getCurrentAudioPosition();

                        int duration = service.audioServiceBinder.getAudioPlayer().getDuration();

                        if (position <= duration) {

                            JSONObject message = new JSONObject();

                            message.put("name", "onTime");

                            message.put("time",
                                    service.audioServiceBinder.getCurrentAudioPosition() / 1000);

                            service.eventSink.success(message);
                        }

                    } catch (Exception e) { /* ignore */ }

                } else if (msg.what == service.audioServiceBinder.UPDATE_PLAYER_STATE_TO_PAUSE) {

                    service.notifyDartOnPause();

                } else if (msg.what == service.audioServiceBinder.UPDATE_PLAYER_STATE_TO_PLAY) {

                    service.notifyDartOnPlay();

                } else if (msg.what == service.audioServiceBinder.UPDATE_PLAYER_STATE_TO_COMPLETE) {

                    service.notifyDartOnComplete();

                } else if (msg.what == service.audioServiceBinder.UPDATE_PLAYER_STATE_TO_ERROR) {

                    service.notifyDartOnError(msg.obj.toString());

                } else if (msg.what == service.audioServiceBinder.UPDATE_AUDIO_DURATION) {

                    service.onDuration();

                }
            }
        }
    }
}
