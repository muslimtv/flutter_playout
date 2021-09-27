package tv.mta.flutter_playout;

import android.app.Service;
import android.content.Intent;
import android.os.Binder;
import android.os.IBinder;

import androidx.annotation.Nullable;

/**
 * This service is used to clear player notifications if app is
 * killed from recent apps list
 */
public class MediaNotificationManagerService extends Service {

    /**
     * The binder used by clients to access this instance.
     */
    private final Binder mBinder = new MediaNotificationManagerServiceBinder();

    /**
     * The player managed by this service.
     */
    private FlutterAVPlayer avPlayer;

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        return super.onStartCommand(intent, flags, startId);
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return mBinder;
    }

    @Override
    public void onDestroy() {

        try {

            avPlayer.onDestroy();

        } catch (Exception e) { /* ignore */ }
    }

    @Override
    public boolean onUnbind(Intent intent) {

        try {

            avPlayer.onDestroy();

            stopSelf();

        } catch (Exception e) { /* ignore */ }

        return false;
    }

    @Override
    public void onTaskRemoved(Intent rootIntent) {
        super.onTaskRemoved(rootIntent);

        avPlayer.onDestroy();

        stopSelf();
    }

    /**
     * Used to set a player to control the MediaSession for.
     * @param player the player that should be controlled by this service.
     */
    public void setActivePlayer(FlutterAVPlayer player) {

        if (avPlayer != null) {

            avPlayer.onDestroy();
        }

        avPlayer = player;
    }

    /**
     * Clients access this service through this class.
     * Because we know this service always runs in the same process
     * as its clients, we don't need to deal with IPC.
     */
    public class MediaNotificationManagerServiceBinder extends Binder {

        public MediaNotificationManagerService getService() {

            return MediaNotificationManagerService.this;
        }
    }
}