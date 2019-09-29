//
//  AudioPlayer.swift
//  Runner
//
//  Created by Khuram Khalid on 27/09/2019.
//

import Foundation
import AVFoundation
import Flutter
import MediaPlayer

class AudioPlayer: NSObject, FlutterPlugin, FlutterStreamHandler {
    static func register(with registrar: FlutterPluginRegistrar) {
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
        } catch _ { }
        
        let channel = FlutterMethodChannel(name: "tv.mta/NativeAudioChannel", binaryMessenger: registrar.messenger())
        
        registrar.addMethodCallDelegate(AudioPlayer.instance, channel: channel)
        
        setupEventChannel(messenger: registrar.messenger(), instance: AudioPlayer.instance)
    }
    
    private static func setupEventChannel(messenger:FlutterBinaryMessenger, instance:AudioPlayer) {
        
        /* register for Flutter event channel */
        instance.eventChannel = FlutterEventChannel(name: "tv.mta/NativeAudioEventChannel", binaryMessenger: messenger, codec: FlutterJSONMethodCodec.sharedInstance())
        
        instance.eventChannel!.setStreamHandler(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
      /* start audio playback */
      if ("play" == call.method) {
          
          if let arguments = call.arguments as? NSDictionary {
              
              if let audioURL = arguments["url"] as? String {
                  
                  if let title = arguments["title"] as? String {
                      
                      if let subtitle = arguments["subtitle"] as? String {
                          
                          if let duration = arguments["duration"] as? Double {
                              
                              if let position = arguments["position"] as? Double {
                                  
                                  setup(title: title, subtitle: subtitle, position: position, duration: duration, url: audioURL)
                              }
                          }
                      }
                  }
              }
          }
          
          result(true)
      }
      
      /* pause audio playback */
      else if ("pause" == call.method) {
          
          pause()
          
          result(true)
      }
          
      /* stop audio playback */
      else if ("stop" == call.method) {
          
          teardown()
          
          result(true)
      }
          
      /* seek audio playback */
      else if ("seekTo" == call.method) {
          
          if let arguments = call.arguments as? NSDictionary {
              
              if let seekToSecond = arguments["second"] as? Double {
                  
                  seekTo(second: seekToSecond)
              }
          }
          
          result(true)
      }
          
      /* not implemented yet */
      else { result(FlutterMethodNotImplemented) }
    }
    
    static let instance = AudioPlayer()
    
    private override init() { }
    
    private var audioPlayer = AVPlayer()
    
    private var timeObserverToken:Any?
    
    /* Flutter event streamer properties */
    private var eventChannel:FlutterEventChannel?
    private var flutterEventSink:FlutterEventSink?
    
    private var nowPlayingInfo = [String : Any]()
    
    private func setup(title:String, subtitle:String, position:Double, duration:Double, url: String?) {

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(true)
        } catch _ { }
        
        audioPlayer.pause()
        
        if let audioURL = url {
            
            audioPlayer = AVPlayer(url: URL(string: audioURL)!)
            
            let interval = CMTime(seconds: 1.0,
            preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            
            timeObserverToken = audioPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) {
                time in self.onTimeInterval(time: time)
            }
            
            setupRemoteTransportControls()
            
            setupNowPlaying(title: title, subtitle: subtitle, duration: duration)
            
            seekTo(second: position / 1000)
            
            audioPlayer.play()
        }
    }
    
    private func setupRemoteTransportControls() {
        
        let commandCenter = MPRemoteCommandCenter.shared()

        // Add handler for Play Command
        commandCenter.playCommand.addTarget { event in
            if self.audioPlayer.rate == 0.0 {
                self.audioPlayer.play()
                self.flutterEventSink?(["name":"onPlay"])
                return .success
            }
            return .commandFailed
        }

        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { event in
            if self.audioPlayer.rate == 1.0 {
                self.audioPlayer.pause()
                self.flutterEventSink?(["name":"onPause"])
                return .success
            }
            return .commandFailed
        }
    }
    
    private func setupNowPlaying(title:String, subtitle:String, duration:Double) {
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        
        nowPlayingInfo[MPMediaItemPropertyArtist] = subtitle

        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = audioPlayer.currentTime().seconds

        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration / 1000

        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func pause() {
        
        audioPlayer.pause()
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(audioPlayer.currentTime())
        
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func seekTo(second:Double) {
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(audioPlayer.currentTime())
        
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        
        audioPlayer.seek(to: CMTime(seconds: second, preferredTimescale: CMTimeScale(NSEC_PER_SEC))) { (isCompleted) in
            
            self.nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(self.audioPlayer.currentTime())
            
            self.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = self.nowPlayingInfo
        }
    }
    
    private func teardown() {
        
        pause()
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        
        if let timeObserver = timeObserverToken {
            audioPlayer.removeTimeObserver(timeObserver)
            timeObserverToken = nil
        }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false)
        } catch _ { }
    }
    
    private func onTimeInterval(time:CMTime) {
        self.flutterEventSink?(["name":"onTime", "time":self.audioPlayer.currentTime().seconds])
        
        self.nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(self.audioPlayer.currentTime())
        
        self.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = self.nowPlayingInfo
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        flutterEventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        flutterEventSink = nil
        return nil
    }
}
