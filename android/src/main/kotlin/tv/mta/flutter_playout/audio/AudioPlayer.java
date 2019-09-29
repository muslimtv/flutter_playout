package tv.mta.flutter_playout.audio;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Handler;
import android.os.IBinder;
import android.os.Message;

import org.json.JSONObject;

import java.lang.ref.WeakReference;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.JSONMethodCodec;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

public class AudioPlayer implements MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private AudioServiceBinder audioServiceBinder = null;

    private Handler audioProgressUpdateHandler;

    private EventChannel.EventSink eventSink;

    private Context context;

    private String audioURL;

    private String title;

    private String subtitle;

    private int startPositionInMills;

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

                        JSONObject message = new JSONObject();

                        message.put("name", "onTime");

                        message.put("time", service.audioServiceBinder.getCurrentAudioPosition() / 1000);

                        service.eventSink.success(message);

                    } catch (Exception e) { /* ignore */ }

                } else if (msg.what == service.audioServiceBinder.UPDATE_PLAYER_STATE_TO_PAUSE) {

                    service.notifyDartOnPause();

                } else if (msg.what == service.audioServiceBinder.UPDATE_PLAYER_STATE_TO_PLAY) {

                    service.notifyDartOnPlay();
                }
            }
        }
    }

    public AudioPlayer(BinaryMessenger messenger, Context context) {

        this.context = context;

        this.audioProgressUpdateHandler = new IncomingMessageHandler(this);

        new MethodChannel(messenger, "tv.mta/NativeAudioChannel")
                .setMethodCallHandler(this);

        new EventChannel(messenger, "tv.mta/NativeAudioEventChannel", JSONMethodCodec.INSTANCE)
                .setStreamHandler(this);
    }

    @Override
    public void onListen(Object o, EventChannel.EventSink eventSink) {
        this.eventSink = eventSink;
    }

    @Override
    public void onCancel(Object o) {
        this.eventSink = null;
    }

    /* This service connection object is the bridge between activity and background service. */
    private ServiceConnection serviceConnection = new ServiceConnection() {

        @Override
        public void onServiceConnected(ComponentName componentName, IBinder iBinder) {

            /* Cast and assign background service's onBind method returned iBinder object */
            audioServiceBinder = (AudioServiceBinder) iBinder;

            audioServiceBinder.setContext(context);

            audioServiceBinder.setAudioFileUrl(audioURL);

            audioServiceBinder.setTitle(title);

            audioServiceBinder.setSubtitle(subtitle);

            audioServiceBinder.setAudioProgressUpdateHandler(audioProgressUpdateHandler);

            audioServiceBinder.startAudio(startPositionInMills);

            doBindPlayerNotificationManagerService();
        }

        @Override
        public void onServiceDisconnected(ComponentName componentName) {

        }
    };

    /**
     * Whether we have bound to a {@link PlayerNotificationManagerService}.
     */
    private boolean mIsBoundPlayerNotificationManagerService;

    /**
     * The {@link PlayerNotificationManagerService} we are bound to.
     */
    private PlayerNotificationManagerService mPlayerNotificationManagerService;

    /**
     * The {@link ServiceConnection} serves as glue between this activity and the {@link PlayerNotificationManagerService}.
     */
    private ServiceConnection mPlayerNotificationManagerServiceConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName componentName, IBinder service) {

            mPlayerNotificationManagerService = ((PlayerNotificationManagerService.PlayerNotificationManagerServiceBinder) service)
                    .getService();

            mPlayerNotificationManagerService.setActiveSession(audioServiceBinder);
        }

        @Override
        public void onServiceDisconnected(ComponentName componentName) {

            mPlayerNotificationManagerService = null;
        }
    };

    private void doBindPlayerNotificationManagerService() {

        Intent service = new Intent(this.context,
                PlayerNotificationManagerService.class);

        this.context.bindService(service, mPlayerNotificationManagerServiceConnection, Context.BIND_AUTO_CREATE);

        mIsBoundPlayerNotificationManagerService = true;

        this.context.startService(service);
    }

    private void doUnbindPlayerNotificationManagerService() {

        if (mIsBoundPlayerNotificationManagerService) {

            this.context.unbindService(mPlayerNotificationManagerServiceConnection);

            mIsBoundPlayerNotificationManagerService = false;
        }
    }

    void play(Object arguments) {

        if (audioServiceBinder != null) {

            audioServiceBinder.startAudio(startPositionInMills);

        } else {

            java.util.HashMap<String, Object> args = (java.util.HashMap<String, Object>) arguments;

            this.audioURL = (String) args.get("url");

            this.title = (String) args.get("title");

            this.subtitle = (String) args.get("subtitle");

            try {
                this.startPositionInMills = (int) args.get("position");
            } catch (Exception e) { /* ignore */ }

            bindAudioService();
        }

        notifyDartOnPlay();
    }

    void pause() {

        if (audioServiceBinder != null) {

            audioServiceBinder.pauseAudio();
        }

        notifyDartOnPause();
    }

    void notifyDartOnPlay() {

        try {

            JSONObject message = new JSONObject();

            message.put("name", "onPlay");

            eventSink.success(message);

        } catch (Exception e) { /* ignore */ }
    }

    void notifyDartOnPause() {

        try {

            JSONObject message = new JSONObject();

            message.put("name", "onPause");

            eventSink.success(message);

        } catch (Exception e) { /* ignore */ }
    }

    void stop() {

        if (audioServiceBinder != null) {

            audioServiceBinder.stopAudio();

            unBoundAudioService();

            doUnbindPlayerNotificationManagerService();

            audioServiceBinder = null;
        }
    }

    void seekTo(Object arguments) {

        try {

            java.util.HashMap<String, Double> args = (java.util.HashMap<String, Double>) arguments;

            Double position = args.get("second");

            if (audioServiceBinder != null) {

                audioServiceBinder.seekAudio(position.intValue());
            }

        } catch (Exception e) { /* ignore */ }
    }

    /**
     * Bind background service with caller activity. Then this activity can use
     * background service's AudioServiceBinder instance to invoke related methods.
     */
    private void bindAudioService()
    {
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
        }
    }


    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {

        switch (call.method) {
            case "play":
                play(call.arguments);
                result.success(true);
                break;
            case "pause":
                pause();
                result.success(true);
                break;
            case "stop":
                stop();
                result.success(true);
                break;
            case "seekTo":
                seekTo(call.arguments);
                result.success(true);
                break;
            default:
                result.notImplemented();
        }
    }

    public void onDestroy() {

        try {

            unBoundAudioService();

            doUnbindPlayerNotificationManagerService();

        } catch (Exception e) { /* ignore */ }
    }
}
