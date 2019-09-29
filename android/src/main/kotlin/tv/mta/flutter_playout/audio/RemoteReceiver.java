package tv.mta.flutter_playout.audio;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.view.KeyEvent;

public class RemoteReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {

        if (Intent.ACTION_MEDIA_BUTTON.equals(intent.getAction())) {

            final KeyEvent event = intent.getParcelableExtra(Intent.EXTRA_KEY_EVENT);

            if (event != null && event.getAction() == KeyEvent.ACTION_DOWN) {

                switch (event.getKeyCode()) {

                    case KeyEvent.KEYCODE_MEDIA_PAUSE:

                        AudioServiceBinder.currentService.pauseAudio();

                        break;

                    case KeyEvent.KEYCODE_MEDIA_PLAY:

                        AudioServiceBinder.currentService.startAudio(0);

                        break;
                }
            }
        }
    }
}
