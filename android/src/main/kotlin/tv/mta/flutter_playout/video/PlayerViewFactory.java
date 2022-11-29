package tv.mta.flutter_playout.video;

import android.app.Activity;
import android.content.Context;

import androidx.annotation.NonNull;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.JSONMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;
import io.flutter.plugin.platform.PlatformViewRegistry;

public class PlayerViewFactory extends PlatformViewFactory {

    private Activity activity;

    private PlayerView playerView;

    private final BinaryMessenger messenger;

    public static PlayerViewFactory registerWith(PlatformViewRegistry viewRegistry, BinaryMessenger messenger) {

        final PlayerViewFactory plugin = new PlayerViewFactory(messenger);

        viewRegistry.registerViewFactory("tv.mta/NativeVideoPlayer", plugin);

        return plugin;
    }

    public PlayerViewFactory(BinaryMessenger messenger) {

        super(JSONMessageCodec.INSTANCE);

        this.messenger = messenger;
    }

    @NonNull
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
        playerView.setActivity(activity);
    }

    public void onDetachActivity() {
        onDestroy();
    }

    public void addActivity(Activity activity) {
        this.activity = activity;
    }
}