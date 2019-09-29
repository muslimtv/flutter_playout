package tv.mta.flutter_playout.audio;

import android.app.Service;
import android.content.Intent;
import android.os.Binder;
import android.os.IBinder;

import org.jetbrains.annotations.Nullable;

public class PlayerNotificationManagerService extends Service {

    /**
     * The binder used by clients to access this instance.
     */
    private final Binder mBinder = new PlayerNotificationManagerServiceBinder();

    /**
     * The MediaSession managed by this service.
     */
    private AudioServiceBinder mMediaSession;

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

            mMediaSession.stopAudio();

        } catch (Exception e) { /* ignore */ }
    }

    @Override
    public boolean onUnbind(Intent intent) {

        try {

            mMediaSession.stopAudio();

            stopSelf();

        } catch (Exception e) { /* ignore */ }

        return false;
    }

    @Override
    public void onTaskRemoved(Intent rootIntent) {
        super.onTaskRemoved(rootIntent);

        mMediaSession.stopAudio();

        stopSelf();
    }

    public void setActiveSession(AudioServiceBinder session) {

        mMediaSession = session;
    }

    /**
     * Clients access this service through this class.
     * Because we know this service always runs in the same process
     * as its clients, we don't need to deal with IPC.
     */
    public class PlayerNotificationManagerServiceBinder extends Binder {

        PlayerNotificationManagerService getService() {

            return PlayerNotificationManagerService.this;
        }
    }
}
