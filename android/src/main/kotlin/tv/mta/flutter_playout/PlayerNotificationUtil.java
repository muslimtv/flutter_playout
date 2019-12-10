package tv.mta.flutter_playout;

import android.app.Activity;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.support.v4.media.MediaDescriptionCompat;
import android.support.v4.media.MediaMetadataCompat;
import android.support.v4.media.session.MediaControllerCompat;
import android.support.v4.media.session.MediaSessionCompat;
import android.view.KeyEvent;

import androidx.core.app.NotificationCompat;

public class PlayerNotificationUtil  {

    /**
     * Creates a new Notification builder from an existing media session.
     * @param context
     * @param mediaSession
     * @return
     */
    public static NotificationCompat.Builder from(Activity activity,
                                                  Context context,
                                                  MediaSessionCompat mediaSession,
                                                  String notificationChannelId) {

        MediaControllerCompat controller = mediaSession.getController();

        MediaMetadataCompat mediaMetadata = controller.getMetadata();

        MediaDescriptionCompat description = mediaMetadata.getDescription();

        NotificationCompat.Builder builder = new NotificationCompat.Builder(context, notificationChannelId);

        int smallIcon = context.getResources().getIdentifier(
                "ic_notification_icon", "drawable", context.getPackageName());

        builder.setContentTitle(description.getTitle())
                .setContentText(description.getSubtitle())
                .setLargeIcon(description.getIconBitmap())
                .setStyle(new androidx.media.app.NotificationCompat.MediaStyle()
                        .setMediaSession(mediaSession.getSessionToken()))
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setSmallIcon(smallIcon)
                .setDeleteIntent(getActionIntent(context, KeyEvent.KEYCODE_MEDIA_STOP));

        Intent intent = new Intent(context, activity.getClass());

        intent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);

        PendingIntent pendingIntent = PendingIntent.getActivity(context, 0, intent, 0);

        builder.setContentIntent(pendingIntent);

        return builder;
    }

    public static PendingIntent getActionIntent(Context context, int mediaKeyEvent) {

        Intent intent = new Intent(Intent.ACTION_MEDIA_BUTTON);

        intent.setPackage(context.getPackageName());

        intent.putExtra(Intent.EXTRA_KEY_EVENT, new KeyEvent(KeyEvent.ACTION_DOWN, mediaKeyEvent));

        return PendingIntent.getBroadcast(context, mediaKeyEvent, intent, 0);
    }
}