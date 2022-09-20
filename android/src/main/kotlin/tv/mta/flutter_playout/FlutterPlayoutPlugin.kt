package tv.mta.flutter_playout

import android.app.Activity
import android.util.Log
import tv.mta.flutter_playout.audio.AudioPlayer
import tv.mta.flutter_playout.video.PlayerViewFactory

import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

class FlutterPlayoutPlugin: FlutterPlugin, ActivityAware {

  private lateinit var activity : Activity

  private lateinit var playerViewFactory : PlayerViewFactory

  private lateinit var audioPlayerFactory : AudioPlayer

  private lateinit var pluginBinding : FlutterPlugin.FlutterPluginBinding

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    pluginBinding = flutterPluginBinding
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    playerViewFactory.onDetachActivity()
    audioPlayerFactory.onDetachActivity()
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    try {
      playerViewFactory = PlayerViewFactory.registerWith(
        pluginBinding.platformViewRegistry,
        pluginBinding.binaryMessenger,
        activity)
    } catch (e: Exception) {
      Log.d("playerViewFactory", e.toString())
    }

    try {
      audioPlayerFactory = AudioPlayer.registerWith(pluginBinding.binaryMessenger,
        activity, pluginBinding.applicationContext)
    } catch (e: Exception) {
    }
    playerViewFactory.onAttachActivity(binding.activity)
    audioPlayerFactory.onAttachActivity(binding.activity)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    playerViewFactory.onDetachActivity()
    audioPlayerFactory.onDetachActivity()
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    playerViewFactory.onAttachActivity(binding.activity)
    audioPlayerFactory.onAttachActivity(binding.activity)
  }

  override fun onDetachedFromActivity() {
    playerViewFactory.onDetachActivity()
    audioPlayerFactory.onDetachActivity()
  }
}
