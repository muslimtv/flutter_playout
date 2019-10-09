//
//  VideoPlayer.swift
//  flutter_playout
//
//  Created by Khuram Khalid on 08/10/2019.
//

import Foundation
import AVFoundation
import Flutter
import MediaPlayer
import AVKit

class VideoPlayerFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger:FlutterBinaryMessenger
    
    /* register video player */
    static func register(with registrar: FlutterPluginRegistrar) {
        registrar.register(VideoPlayerFactory(messenger: registrar.messenger()), withId: "tv.mta/NativeVideoPlayer")
    }
    
    init(messenger:FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }
    
    public func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return VideoPlayer(frame: frame, viewId: viewId, messenger: messenger, args: args)
    }
    
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterJSONMessageCodec()
    }
}

class VideoPlayer: NSObject, FlutterStreamHandler, FlutterPlatformView {
    
    /* view specific properties */
    var frame:CGRect
    var viewId:Int64
    
    /* player properties */
    var player: FluterAVPlayer?
    var playerLayer:AVPlayerLayer?
    var playerViewController:AVPlayerViewController?
    
    /* player metadata */
    var url:String = ""
    var autoPlay:Bool = false
    var title:String = ""
    var subtitle:String = ""
    
    private var timeObserverToken:Any?
    
    let requiredAssetKeys = [
        "playable",
    ]
    
    /* Flutter event streamer properties */
    private var eventChannel:FlutterEventChannel?
    private var flutterEventSink:FlutterEventSink?
    
    private var nowPlayingInfo = [String : Any]()
    
    deinit {
        print("[dealloc] tv.mta/NativeVideoPlayer")
    }
    
    init(frame:CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, args: Any?) {
        
        /* set view properties */
        self.frame = frame
        self.viewId = viewId
        
        super.init()
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
        } catch _ { }
        
        setupEventChannel(viewId: viewId, messenger: messenger, instance: self)
        
        /* data as JSON */
        let parsedData = args as! [String: Any]

        /* set incoming player properties */
        self.url = parsedData["url"] as! String
        self.autoPlay = parsedData["autoPlay"] as! Bool
        self.title = parsedData["title"] as! String
        self.subtitle = parsedData["subtitle"] as! String
    }
    
    /* set Flutter messenger */
    private func setupEventChannel(viewId: Int64, messenger:FlutterBinaryMessenger, instance:VideoPlayer) {
        
        /* register for Flutter event channel */
        instance.eventChannel = FlutterEventChannel(name: "tv.mta/NativeVideoPlayerEventChannel_" + String(viewId), binaryMessenger: messenger, codec: FlutterJSONMethodCodec.sharedInstance())
        
        instance.eventChannel!.setStreamHandler(instance)
    }
    
    /* create player view */
    func view() -> UIView {
        
        if let videoURL = URL(string: self.url) {
            
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setActive(true)
            } catch _ { }
            
            /* Create the asset to play */
            let asset = AVAsset(url: videoURL)

            /* Create a new AVPlayerItem with the asset and
             an array of asset keys to be automatically loaded */
            let playerItem = AVPlayerItem(asset: asset,
                                      automaticallyLoadedAssetKeys: requiredAssetKeys)
            
            let center = NotificationCenter.default
            
            center.addObserver(self, selector: #selector(onComplete(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem)
            center.addObserver(self, selector:#selector(onAVPlayerNewErrorLogEntry(_:)), name: .AVPlayerItemNewErrorLogEntry, object: player?.currentItem)
            center.addObserver(self, selector:#selector(onAVPlayerFailedToPlayToEndTime(_:)), name: .AVPlayerItemFailedToPlayToEndTime, object: player?.currentItem)
            
            /* setup player */
            self.player = FluterAVPlayer(playerItem: playerItem)
            
            /* Add observer for AVPlayer status and AVPlayerItem status */
            self.player?.addObserver(self, forKeyPath: #keyPath(AVPlayer.status), options: [.new, .initial], context: nil)
            self.player?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options:[.old, .new, .initial], context: nil)
            self.player?.addObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), options:[.old, .new, .initial], context: nil)
                    
            /* setup callback for onTime */
            let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) {
                time in self.onTimeInterval(time: time)
            }
            
            /* setup player view controller */
            self.playerViewController = AVPlayerViewController()
            self.playerViewController?.player = self.player
            self.playerViewController?.view.frame = self.frame
            
            /* setup lock screen controls */
            setupRemoteTransportControls()
            setupNowPlaying()
            
            /* start playback if set to auto play */
            if (self.autoPlay) {
                play()
            }
            
            /* add player view controller to root view controller */
            let viewController = (UIApplication.shared.delegate?.window??.rootViewController)!
            viewController.addChildViewController(self.playerViewController!)
            
            /* return player view controller's view */
            return self.playerViewController!.view
        }
        
        /* return default view if videoURL isn't valid */
        return UIView()
    }
    
    @objc func onComplete(_ notification: Notification) {
        self.flutterEventSink?(["name":"onComplete"])
    }
    
    /* observe AVPlayer.status, AVPlayerItem.status & AVPlayer.timeControlStatus */
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == #keyPath(AVPlayer.status) {
            /* player status notification */
        } else if keyPath == #keyPath(AVPlayerItem.status) {
            
            let newStatus: AVPlayerItemStatus
            
            if let newStatusAsNumber = change?[NSKeyValueChangeKey.newKey] as? NSNumber {
                newStatus = AVPlayerItemStatus(rawValue: newStatusAsNumber.intValue)!
            } else {
                newStatus = .unknown
            }
            
            if newStatus == .failed {
                self.flutterEventSink?(["name":"onError", "error":(String(describing: self.player?.currentItem?.error))])
            }
        }
        
        else if keyPath == #keyPath(AVPlayer.timeControlStatus) {
            
            guard let p = object as! AVPlayer? else {
                return
            }
            
            if #available(iOS 10.0, *) {
                
                switch (p.timeControlStatus) {
                
                case AVPlayerTimeControlStatus.paused:
                    self.flutterEventSink?(["name":"onPause"])
                    break
                
                case AVPlayerTimeControlStatus.playing:
                    self.flutterEventSink?(["name":"onPlay"])
                    break
                
                case .waitingToPlayAtSpecifiedRate: break
                }
            } else {
                // Fallback on earlier versions
            }
        } else {
            super.observeValue(forKeyPath: keyPath,
                               of: object,
                               change: change,
                               context: context)
            return
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
            if self.player?.rate == 0.0 {
                self.play()
                return .success
            }
            return .commandFailed
        }

        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { event in
            if self.player?.rate == 1.0 {
                self.pause()
                return .success
            }
            return .commandFailed
        }
    }
    
    private func setupNowPlaying() {
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = self.title
        
        nowPlayingInfo[MPMediaItemPropertyArtist] = self.subtitle

        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player?.currentTime().seconds

        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player?.currentItem?.asset.duration.seconds

        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func play() {
        player?.play()
    }
    
    private func pause() {
        player?.pause()
    }
    
    private func seekTo(second:Double) {
        
        let beforeSeek = player?.currentTime().seconds
        
        player?.seek(to: CMTime(seconds: second, preferredTimescale: CMTimeScale(NSEC_PER_SEC))) { (isCompleted) in
            
            self.flutterEventSink?(["name":"onSeek", "position":beforeSeek ?? 0, "offset":second])
        }
    }
    
    private func teardown() {
        
        pause()
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        
        if let timeObserver = timeObserverToken {
            player?.removeTimeObserver(timeObserver)
            timeObserverToken = nil
        }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false)
        } catch _ { }
    }
    
    private func onTimeInterval(time:CMTime) {
        self.flutterEventSink?(["name":"onTime", "time":self.player?.currentTime().seconds ?? 0])
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        flutterEventSink = events
        self.player?.flutterEventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        flutterEventSink = nil
        self.player?.flutterEventSink = nil
        return nil
    }
    
    public func dispose() {
        if self.player != nil {
            self.player?.pause()
            self.player = nil
        }
        
        self.flutterEventSink = nil
        self.player?.flutterEventSink = nil
        self.eventChannel?.setStreamHandler(nil)
    }
}

class FluterAVPlayer: AVPlayer {
    var flutterEventSink:FlutterEventSink?
    
    override func seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime, completionHandler: @escaping (Bool) -> Void) {
        
        let position = self.currentTime().seconds
        
        super.seek(to: time, toleranceBefore: toleranceAfter, toleranceAfter: toleranceAfter, completionHandler: { (isCompleted) in
            
            if (isCompleted) {
                
                let offset = time.seconds
                
                self.flutterEventSink?(["name":"onSeek", "position":position, "offset":offset])
            }
            
            /* call super completion handler */
            completionHandler(isCompleted)
        })
    }
}
