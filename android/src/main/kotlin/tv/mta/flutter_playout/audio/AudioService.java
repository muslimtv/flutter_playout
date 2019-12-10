package tv.mta.flutter_playout.audio;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;

public class AudioService extends Service {

    private AudioServiceBinder audioServiceBinder = new AudioServiceBinder();

    public AudioService() {
    }

    @Override
    public IBinder onBind(Intent intent) {
        return audioServiceBinder;
    }

    @Override
    public void onDestroy() {
        audioServiceBinder.onDestroy();
        super.onDestroy();
    }

    @Override
    public void onTaskRemoved(Intent rootIntent) {
        audioServiceBinder.onDestroy();
        super.onTaskRemoved(rootIntent);
    }

    @Override
    public boolean onUnbind(Intent intent) {
        audioServiceBinder.onDestroy();
        return super.onUnbind(intent);
    }
}