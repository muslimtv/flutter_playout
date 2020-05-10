package tv.mta.flutter_playout

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry.Registrar
import tv.mta.flutter_playout.audio.AudioPlayer
import tv.mta.flutter_playout.video.PlayerViewFactory

class FlutterPlayoutPlugin: FlutterPlugin, ActivityAware {

  private lateinit var playerViewFactory : PlayerViewFactory

  private lateinit var audioPlayerFactory : AudioPlayer

  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      PlayerViewFactory.registerWith(registrar)
      AudioPlayer.registerWith(registrar)
    }
  }

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    playerViewFactory = PlayerViewFactory.registerWith(binding)
    audioPlayerFactory = AudioPlayer.registerWith(binding)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    playerViewFactory?.onDestroy()
    audioPlayerFactory?.onDestroy()
  }

  override fun onDetachedFromActivity() {
    playerViewFactory?.onDetachedFromActivity()
    audioPlayerFactory?.onDetachedFromActivity()
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    playerViewFactory?.onReattachedToActivityForConfigChanges(binding.activity)
    audioPlayerFactory?.onReattachedToActivityForConfigChanges(binding.activity)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    playerViewFactory?.onAttachedToActivity(binding.activity)
    audioPlayerFactory?.onAttachedToActivity(binding.activity)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    playerViewFactory?.onDetachedFromActivityForConfigChanges()
    audioPlayerFactory?.onDetachedFromActivityForConfigChanges()
  }
}
