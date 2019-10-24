package tv.mta.flutter_playout.audio;

import android.app.Activity;
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
import io.flutter.view.FlutterNativeView;
import tv.mta.flutter_playout.MediaNotificationManagerService;

public class AudioPlayer implements MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

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

    public static void registerWith(PluginRegistry.Registrar registrar) {

        final AudioPlayer plugin = new AudioPlayer(registrar.messenger(), registrar.activeContext());

        plugin.activity = registrar.activity();

        MethodChannel channel = new MethodChannel(registrar.messenger(), "tv.mta/PluginRegistrar");

        channel.setMethodCallHandler(plugin);

        registrar.addViewDestroyListener(new PluginRegistry.ViewDestroyListener() {
            @Override
            public boolean onViewDestroy(FlutterNativeView view) {
                plugin.onDestroy();
                return false;
            }
        });
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

                } else if (msg.what == service.audioServiceBinder.UPDATE_AUDIO_DURATION) {

                    service.onDuration();
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

            mMediaNotificationManagerService.setActivePlayer(audioServiceBinder);
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

    void notifyDartOnComplete() {

        try {

            JSONObject message = new JSONObject();

            message.put("name", "onComplete");

            eventSink.success(message);

        } catch (Exception e) { /* ignore */ }
    }

    void stop() {

        if (audioServiceBinder != null) {

            audioServiceBinder.stopAudio();

            unBoundAudioService();

            doUnbindMediaNotificationManagerService();

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

    void onDuration() {

        try {

            int newDuration = audioServiceBinder.getAudioPlayer().getDuration();

            if (newDuration != mediaDuration) {

                mediaDuration = newDuration;

                JSONObject message = new JSONObject();

                message.put("name", "onDuration");

                message.put("duration", mediaDuration);

                eventSink.success(message);
            }

        } catch (Exception e) { /* ignore */ System.out.println(e); }
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

            doUnbindMediaNotificationManagerService();

        } catch (Exception e) { /* ignore */ }
    }
}
