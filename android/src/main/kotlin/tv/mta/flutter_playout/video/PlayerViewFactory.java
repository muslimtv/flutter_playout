package tv.mta.flutter_playout.video;

import android.app.Activity;
import android.content.Context;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.JSONMessageCodec;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;
import io.flutter.plugin.platform.PlatformViewRegistry;
import io.flutter.view.FlutterNativeView;

public class PlayerViewFactory extends PlatformViewFactory {

    private Activity activity;

    private  PlayerView playerView;

    private final BinaryMessenger messenger;

    public static PlayerViewFactory registerWith(PlatformViewRegistry viewRegistry, BinaryMessenger messenger, Activity activity) {

        final PlayerViewFactory plugin = new PlayerViewFactory(messenger, activity);

        viewRegistry.registerViewFactory("tv.mta/NativeVideoPlayer", plugin);

        return plugin;
    }

    public PlayerViewFactory(BinaryMessenger messenger, Activity activity) {

        super(JSONMessageCodec.INSTANCE);

        this.activity = activity;

        this.messenger = messenger;
    }

    @Override
    public PlatformView create(Context context, int id, Object args) {

        playerView = new PlayerView(context, activity, id, messenger, args);

        return playerView;
    }

    public void onDestroy() {

        if (playerView != null) {

            playerView.dispose();
        }
    }

    public void onAttachActivity(Activity activity) {
        this.activity = activity;
        if (playerView != null) {
            playerView.setActivity(activity);
        }
    }

    public void onDetachActivity() {
        onDestroy();
    }
}