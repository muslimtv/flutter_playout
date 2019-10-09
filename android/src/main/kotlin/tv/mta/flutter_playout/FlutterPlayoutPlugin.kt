package tv.mta.flutter_playout

import io.flutter.plugin.common.PluginRegistry.Registrar
import tv.mta.flutter_playout.audio.AudioPlayer

class FlutterPlayoutPlugin {
  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      AudioPlayer.registerWith(registrar)
    }
  }
}
