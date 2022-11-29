package tv.mta.flutter_playout

import android.app.Activity
import tv.mta.flutter_playout.audio.AudioPlayer
import tv.mta.flutter_playout.video.PlayerViewFactory

import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

class FlutterPlayoutPlugin: FlutterPlugin, ActivityAware {

  private lateinit var activity : Activity

  private lateinit var playerViewFactory : PlayerViewFactory

  private lateinit var audioPlayerFactory : AudioPlayer

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    try {
      playerViewFactory = PlayerViewFactory.registerWith(
              flutterPluginBinding.platformViewRegistry,
              flutterPluginBinding.binaryMessenger)
    } catch (e: Exception) {
      throw e
    }

    /*try {
      audioPlayerFactory = AudioPlayer.registerWith(flutterPluginBinding.binaryMessenger,
              activity, flutterPluginBinding.applicationContext)
    } catch (e: Exception) {
      throw e
    }*/
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    playerViewFactory.onDetachActivity()
    audioPlayerFactory.onDetachActivity()
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    playerViewFactory.onAttachActivity(binding.activity)
    playerViewFactory.addActivity(binding.activity)
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
