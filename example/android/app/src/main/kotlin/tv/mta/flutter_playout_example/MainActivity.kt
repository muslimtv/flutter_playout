package tv.mta.flutter_playout_example

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import tv.mta.flutter_playout.audio.AudioPlayer
import tv.mta.flutter_playout.video.PlayerViewFactory

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        PlayerViewFactory.registerWith(
                flutterEngine.platformViewsController.registry,
                flutterEngine.dartExecutor.binaryMessenger,
                this)

        AudioPlayer.registerWith(
                flutterEngine.dartExecutor.binaryMessenger,
                this, context)
    }
}