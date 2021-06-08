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
        
        let player = AudioPlayer()
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback)
        } catch _ { }
        
        let channel = FlutterMethodChannel(name: "tv.mta/NativeAudioChannel", binaryMessenger: registrar.messenger())
        
        registrar.addMethodCallDelegate(player, channel: channel)
        
        setupEventChannel(messenger: registrar.messenger(), instance: player)
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
                          
                          if let position = arguments["position"] as? Double {
                            
                            if let isLiveStream = arguments["isLiveStream"] as? Bool {
                                
                                setup(title: title, subtitle: subtitle, position: position, url: audioURL, isLiveStream: isLiveStream)
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
        
        /* reset audio playback */
        else if ("reset" == call.method) {
            
            reset()
            
            result(true)
        }
          
      /* seek audio playback */
      else if ("seekTo" == call.method) {
          
          if let arguments = call.arguments as? NSDictionary {
              
              if let seekToSecond = arguments["second"] as? Double {
                  
                  seekTo(seconds: seekToSecond)
              }
          }
          
          result(true)
      }
        
        /* stop audio playback */
        else if ("dispose" == call.method) {
            
            teardown()
            
            result(true)
        }
          
      /* not implemented yet */
      else { result(FlutterMethodNotImplemented) }
    }
    
    private override init() { }
    
    private var audioPlayer = AVPlayer()
    
    private var timeObserverToken:Any?
    
    /* Flutter event streamer properties */
    private var eventChannel:FlutterEventChannel?
    private var flutterEventSink:FlutterEventSink?
    
    private var nowPlayingInfo = [String : Any]()
    
    private var mediaDuration = 0.0
    
    private var mediaURL = ""
    
    private func setup(title:String, subtitle:String, position:Double, url: String?, isLiveStream:Bool) {

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(AVAudioSession.Category.playback, options: AVAudioSession.CategoryOptions.allowBluetooth)
            try audioSession.setActive(true)
        } catch _ { }
        
        audioPlayer.pause()
        
        var validPlaybackUrl = false
        
        if let audioURL = url {
            
            if let url = URL(string: audioURL) {
            
                /* Create the asset to play */
                let asset = AVAsset(url: url)
                
                if (asset.isPlayable) {
                    
                    validPlaybackUrl = true
                
                    if (audioURL != mediaURL) {
                        
                        mediaURL = audioURL
                        
                        audioPlayer = AVPlayer(url: url)
                        
                        let center = NotificationCenter.default
                        
                        center.addObserver(self, selector: #selector(onComplete(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.audioPlayer.currentItem)
                        center.addObserver(self, selector:#selector(onAVPlayerNewErrorLogEntry(_:)), name: .AVPlayerItemNewErrorLogEntry, object: audioPlayer.currentItem)
                        center.addObserver(self, selector:#selector(onAVPlayerFailedToPlayToEndTime(_:)), name: .AVPlayerItemFailedToPlayToEndTime, object: audioPlayer.currentItem)
                        
                        /* Add observer for AVPlayer status and AVPlayerItem status */
                        self.audioPlayer.addObserver(self, forKeyPath: #keyPath(AVPlayer.status), options: [.new, .initial], context: nil)
                        self.audioPlayer.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options:[.old, .new, .initial], context: nil)
                        if #available(iOS 10.0, *) {
                            self.audioPlayer.addObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), options:[.old, .new, .initial], context: nil)
                        } else {
                            // Fallback on earlier versions
                        }
                        
                        let interval = CMTime(seconds: 1.0,
                        preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                        
                        timeObserverToken = audioPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) {
                            time in self.onTimeInterval(time: time)
                        }
                        
                        setupRemoteTransportControls()
                        
                        setupNowPlayingInfoPanel(title: title, subtitle: subtitle, isLiveStream: isLiveStream)
                        
                        seekTo(seconds: position / 1000)
                        
                    }
                    
                    audioPlayer.play()
                }
            }
        }
        
        if (!validPlaybackUrl) {
            pause()
        }
    }
    
    @objc func onComplete(_ notification: Notification) {
        
        pause()
        
        self.flutterEventSink?(["name":"onComplete"])
        
        seekTo(seconds: 0.0)
        
        updateInfoPanelOnComplete()
    }
    
    /* Observe If AVPlayerItem.status Changed to Fail */
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        
            if keyPath == #keyPath(AVPlayerItem.status) {
                
                let newStatus: AVPlayerItem.Status
                
                if let newStatusAsNumber = change?[NSKeyValueChangeKey.newKey] as? NSNumber {
                    newStatus = AVPlayerItem.Status(rawValue: newStatusAsNumber.intValue)!
                } else {
                    newStatus = .unknown
                }
                
                if newStatus == .failed {
                    self.flutterEventSink?(["name":"onError", "error":(String(describing: self.audioPlayer.currentItem?.error))])
                } else if newStatus == .readyToPlay {
                    self.flutterEventSink?(["name":"onReady"])
                }
            }
            
        if #available(iOS 10.0, *) {
            if keyPath == #keyPath(AVPlayer.timeControlStatus) {
                
                guard let p = object as! AVPlayer? else {
                    return
                }
                
                switch (p.timeControlStatus) {
                
                case AVPlayer.TimeControlStatus.paused:
                    self.flutterEventSink?(["name":"onPause"])
                    break
                    
                case AVPlayer.TimeControlStatus.playing:
                    self.flutterEventSink?(["name":"onPlay"])
                    break
                    
                case .waitingToPlayAtSpecifiedRate: break
                @unknown default:
                    break
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    @objc func onAVPlayerNewErrorLogEntry(_ notification: Notification) {
        guard let object = notification.object, let playerItem = object as? AVPlayerItem else {
            return
        }
        guard let error: AVPlayerItemErrorLog = playerItem.errorLog() else {
            return
        }
        guard var errorMessage = error.extendedLogData() else {
            return
        }
        
        errorMessage.removeLast()
        
        self.flutterEventSink?(["name":"onError", "error":String(data: errorMessage, encoding: .utf8)])
    }

    @objc func onAVPlayerFailedToPlayToEndTime(_ notification: Notification) {
        guard let error = notification.userInfo!["AVPlayerItemFailedToPlayToEndTimeErrorKey"] else {
            return
        }
        self.flutterEventSink?(["name":"onError", "error":error])
    }
    
    private func setupRemoteTransportControls() {
        
        let commandCenter = MPRemoteCommandCenter.shared()

        // Add handler for Play Command
        commandCenter.playCommand.addTarget { event in
            if self.audioPlayer.rate == 0.0 {
                self.play()
                return .success
            }
            return .commandFailed
        }

        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { event in
            if self.audioPlayer.rate == 1.0 {
                self.pause()
                return .success
            }
            return .commandFailed
        }
    }
    
    private func setupNowPlayingInfoPanel(title:String, subtitle:String, isLiveStream:Bool) {
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        
        nowPlayingInfo[MPMediaItemPropertyArtist] = subtitle
        
        if #available(iOS 10.0, *) {
            nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = isLiveStream
        }

        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = audioPlayer.currentTime().seconds

        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = audioPlayer.currentItem?.asset.duration.seconds

        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0 // will be set to 1 by onTime callback

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func play() {
        
        audioPlayer.play()
        
        self.flutterEventSink?(["name":"onPlay"])
        
        updateInfoPanelOnPlay()
        
        onDurationChange()
    }
    
    private func pause() {
        
        audioPlayer.pause()
        
        self.flutterEventSink?(["name":"onPause"])
        
        updateInfoPanelOnPause()
        
        onDurationChange()
    }
    
    private func seekTo(seconds:Double) {
        
        updateInfoPanelOnPause()
        
        let position = self.audioPlayer.currentTime().seconds
        
        audioPlayer.seek(to: CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))) { (isCompleted) in
            
            if (isCompleted) {
                
                self.flutterEventSink?(["name":"onSeek", "position":position, "offset":seconds])
            }
            
            self.updateInfoPanelOnPlay()
        }
    }
    
    private func reset() {
        
        audioPlayer.pause()
        
        seekTo(seconds: 0.0)
        
        /* reset state */
        self.mediaURL = ""
        
        onDurationChange()
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    private func teardown() {
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        
        if let timeObserver = timeObserverToken {
            audioPlayer.removeTimeObserver(timeObserver)
            timeObserverToken = nil
        }
        
        /* stop playback */
        self.audioPlayer.pause()
        
        /* reset state */
        self.mediaURL = ""
        self.mediaDuration = 0.0
        
        NotificationCenter.default.removeObserver(self)
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false)
        } catch _ { }
    }
    
    private func onTimeInterval(time:CMTime) {
        
        self.flutterEventSink?(["name":"onTime", "time":self.audioPlayer.currentTime().seconds])
        
        updateInfoPanelOnTime()
        
        onDurationChange()
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        flutterEventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        flutterEventSink = nil
        return nil
    }
    
    private func updateInfoPanelOnPause() {
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds((self.audioPlayer.currentTime()))
        
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func updateInfoPanelOnPlay() {
        
        self.nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(((self.audioPlayer.currentTime())))
        
        self.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = self.nowPlayingInfo
    }
    
    private func updateInfoPanelOnComplete() {
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0

        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func updateInfoPanelOnTime() {
        
        self.nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds((self.audioPlayer.currentTime()))
        
        self.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = self.nowPlayingInfo
    }
    
    private func onDurationChange() {
        
        guard let item = self.audioPlayer.currentItem else { return }
        
        let newDuration = item.duration.seconds * 1000
        
        if (newDuration.isNaN) {
            
            self.mediaDuration = newDuration
            
            self.flutterEventSink?(["name":"onDuration", "duration":-1])
            
        } else if (newDuration != mediaDuration) {
            
            self.mediaDuration = newDuration
            
            self.flutterEventSink?(["name":"onDuration", "duration":self.mediaDuration])
        }
    }
}
