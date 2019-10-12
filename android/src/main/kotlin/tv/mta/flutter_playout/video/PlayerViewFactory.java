package tv.mta.flutter_playout.video;

import android.app.Activity;
import android.content.Context;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.JSONMessageCodec;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;
import io.flutter.view.FlutterNativeView;

public class PlayerViewFactory extends PlatformViewFactory {

    private final Activity activity;

    private PlayerView playerView;

    private BinaryMessenger messenger;

    public static void registerWith(PluginRegistry.Registrar registrar) {

        final PlayerViewFactory plugin = new PlayerViewFactory(registrar.messenger(), registrar.activity());

        registrar.platformViewRegistry().registerViewFactory("tv.mta/NativeVideoPlayer", plugin);

        registrar.addViewDestroyListener(new PluginRegistry.ViewDestroyListener() {
            @Override
            public boolean onViewDestroy(FlutterNativeView view) {
                plugin.onDestroy();
                return false;
            }
        });
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
}