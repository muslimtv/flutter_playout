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
    
    var videoPlayer:VideoPlayer?
    
    var registrar:FlutterPluginRegistrar?
    
    private var messenger:FlutterBinaryMessenger
    
    /* register video player */
    static func register(with registrar: FlutterPluginRegistrar) {
        
        let plugin = VideoPlayerFactory(messenger: registrar.messenger())
        
        plugin.registrar = registrar
            
        registrar.register(plugin, withId: "tv.mta/NativeVideoPlayer")
    }
    
    init(messenger:FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }
    
    public func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        
        self.videoPlayer = VideoPlayer(frame: frame, viewId: viewId, messenger: messenger, args: args)
        
        self.registrar?.addApplicationDelegate(self.videoPlayer!)
        
        return self.videoPlayer!
    }
    
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterJSONMessageCodec()
    }
    
    public func applicationDidEnterBackground() {}
    
    public func applicationWillEnterForeground() {}
}

class VideoPlayer: NSObject, FlutterPlugin, FlutterStreamHandler, FlutterPlatformView {
    
    static func register(with registrar: FlutterPluginRegistrar) { }
    
    /* view specific properties */
    var frame:CGRect
    var viewId:Int64
    
    /* player properties */
    var player: FluterAVPlayer?
    var playerViewController:AVPlayerViewController?
    
    /* player metadata */
    var url:String = ""
    var autoPlay:Bool = true
    var loop:Bool = false
    var title:String = ""
    var subtitle:String = ""
    var isLiveStream:Bool = false
    var showControls:Bool = false
    var position:Double = 0.0

    private var mediaDuration = 0.0

    private var isPlaying = false
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
            try audioSession.setCategory(AVAudioSession.Category.playback)
        } catch _ { }

        setupEventChannel(viewId: viewId, messenger: messenger, instance: self)

        setupMethodChannel(viewId: viewId, messenger: messenger)

        /* data as JSON */
        let parsedData = args as! [String: Any]

        /* set incoming player properties */
        self.url = parsedData["url"] as! String
        self.autoPlay = parsedData["autoPlay"] as! Bool
        self.loop = parsedData["loop"] as! Bool
        self.title = parsedData["title"] as! String
        self.subtitle = parsedData["subtitle"] as! String
        self.isLiveStream = parsedData["isLiveStream"] as! Bool
        self.showControls = parsedData["showControls"] as! Bool
        self.position = parsedData["position"] as! Double

        setupPlayer()
    }

    /* set Flutter event channel */
    private func setupEventChannel(viewId: Int64, messenger:FlutterBinaryMessenger, instance:VideoPlayer) {

        /* register for Flutter event channel */
        instance.eventChannel = FlutterEventChannel(name: "tv.mta/NativeVideoPlayerEventChannel_" + String(viewId), binaryMessenger: messenger, codec: FlutterJSONMethodCodec.sharedInstance())

        instance.eventChannel!.setStreamHandler(instance)
    }

    /* set Flutter method channel */
    private func setupMethodChannel(viewId: Int64, messenger:FlutterBinaryMessenger) {

        let nativeMethodsChannel = FlutterMethodChannel(name: "tv.mta/NativeVideoPlayerMethodChannel_" + String(viewId), binaryMessenger: messenger);

        nativeMethodsChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in

            if ("onMediaChanged" == call.method) {

                /* data as JSON */
                let parsedData = call.arguments as! [String: Any]

                /* set incoming player properties */
                self.url = parsedData["url"] as! String
                self.autoPlay = parsedData["autoPlay"] as! Bool
                self.loop = parsedData["loop"] as! Bool
                self.title = parsedData["title"] as! String
                self.subtitle = parsedData["subtitle"] as! String
                self.isLiveStream = parsedData["isLiveStream"] as! Bool
                self.showControls = parsedData["showControls"] as! Bool
                self.position = parsedData["position"] as! Double

                self.onMediaChanged()

                result(true)
            }

            if ("seekTo" == call.method) {
                /* data as JSON */
                let parsedData = call.arguments as! [String: Any]

                self.position = parsedData["position"] as! Double

                self.player?.seek(to: CMTime(seconds: self.position, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))

                result(true)
            }

            if ("onShowControlsFlagChanged" == call.method) {

                /* data as JSON */
                let parsedData = call.arguments as! [String: Any]

                /* set incoming player controls flag */
                self.showControls = parsedData["showControls"] as! Bool

                self.onShowControlsFlagChanged()

                result(true)
            }

            else if ("resume" == call.method) {
                self.play()
            }

            else if ("pause" == call.method) {
                self.pause()
            }

            /* dispose */
            else if ("dispose" == call.method) {

                self.dispose()

                result(true)
            }

            /* not implemented yet */
            else { result(FlutterMethodNotImplemented) }
        })
    }

    func setupPlayer(){
        if let videoURL = URL(string: self.url.trimmingCharacters(in: .whitespacesAndNewlines)) {

            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(AVAudioSession.Category.playback, options: AVAudioSession.CategoryOptions.allowBluetooth)
                try audioSession.setActive(true)
            } catch _ { }

            /* Create the asset to play */
            let asset = AVAsset(url: videoURL)

            if (asset.isPlayable) {
                /* Create a new AVPlayerItem with the asset and
                 an array of asset keys to be automatically loaded */
                let playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: requiredAssetKeys)

                /* setup player */
                self.player = FluterAVPlayer(playerItem: playerItem)
            }
            else {
                /* not a valid playback asset */
                /* setup empty player */
                self.player = FluterAVPlayer()
            }

            let center = NotificationCenter.default

            center.addObserver(self, selector: #selector(onComplete(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem)
            center.addObserver(self, selector:#selector(onAVPlayerNewErrorLogEntry(_:)), name: .AVPlayerItemNewErrorLogEntry, object: player?.currentItem)
            center.addObserver(self, selector:#selector(onAVPlayerFailedToPlayToEndTime(_:)), name: .AVPlayerItemFailedToPlayToEndTime, object: player?.currentItem)

            if #available(iOS 12.0, *) {
                self.player?.preventsDisplaySleepDuringVideoPlayback = true
            }

            /* Add observer for AVPlayer status and AVPlayerItem status */
            self.player?.addObserver(self, forKeyPath: #keyPath(AVPlayer.status), options: [.new, .initial], context: nil)
            self.player?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options:[.old, .new, .initial], context: nil)
            if #available(iOS 10.0, *) {
                self.player?.addObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), options:[.old, .new, .initial], context: nil)
            }

            /* setup callback for onTime */
            let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) {
                time in self.onTimeInterval(time: time)
            }

            /* setup player view controller */
            self.playerViewController = AVPlayerViewController()
            if #available(iOS 10.0, *) {
                self.playerViewController?.updatesNowPlayingInfoCenter = false
            }

            self.playerViewController?.player = self.player
            self.playerViewController?.view.frame = self.frame
            self.playerViewController?.showsPlaybackControls = self.showControls
            /* setup lock screen controls */
            setupRemoteTransportControls()

            setupNowPlayingInfoPanel()

            /* start playback if svet to auto play */
            if (self.autoPlay) {
                play()
            }

            /* setup loop */
            if (self.loop) {
                NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { [self] notification in
                    self.player?.seek(to: CMTime.zero)
                    player?.play()
                }
            }
            
            /* add player view controller to root view controller */
            let viewController = (UIApplication.shared.delegate?.window??.rootViewController)!
            viewController.addChild(self.playerViewController!)
            
        }
    }
    
    /* create player view */
    func view() -> UIView {
        /* return player view controller's view */
        return self.playerViewController!.view
    }
    
    private func onMediaChanged() {
        if let p = self.player {
            
            if let videoURL = URL(string: self.url) {
                
                /* create the new asset to play */
                let asset = AVAsset(url: videoURL)
                
                let playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: requiredAssetKeys)
                
                p.replaceCurrentItem(with: playerItem)
                
                /* setup lock screen controls */
                setupRemoteTransportControls()
                setupNowPlayingInfoPanel()
            }
        }
    }
    
    private func onShowControlsFlagChanged() {
        self.playerViewController?.showsPlaybackControls = self.showControls
    }
    
    @objc func onComplete(_ notification: Notification) {
        
        pause()
        
        isPlaying = false
        
        self.flutterEventSink?(["name":"onComplete"])
        
        self.player?.seek(to: CMTime(seconds: 0, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
        
        updateInfoPanelOnComplete()
    }
    
    /* observe AVPlayer.status, AVPlayerItem.status & AVPlayer.timeControlStatus */
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == #keyPath(AVPlayer.status) {
            /* player status notification */
        } else if keyPath == #keyPath(AVPlayerItem.status) {
            
            let newStatus: AVPlayerItem.Status
            
            if let newStatusAsNumber = change?[NSKeyValueChangeKey.newKey] as? NSNumber {
                newStatus = AVPlayerItem.Status(rawValue: newStatusAsNumber.intValue)!
            } else {
                newStatus = .unknown
            }
            
            if newStatus == .failed {
                
                isPlaying = false
                
                self.flutterEventSink?(["name":"onError", "error":(String(describing: self.player?.currentItem?.error))])
            
            }
        }
        
        if (keyPath == #keyPath(AVPlayer.status)) {
            guard let p = object as! AVPlayer? else {
                return
            }
            
            switch (p.status) {
            case .readyToPlay:
                break
            case .unknown:
                break
            case .failed:
                break
            @unknown default:
                break
            }
        }
        
        else if #available(iOS 10.0, *) {
            if keyPath == #keyPath(AVPlayer.timeControlStatus) {
                
                guard let p = object as! AVPlayer? else {
                    return
                }
                
                switch (p.timeControlStatus) {
                
                case AVPlayer.TimeControlStatus.paused:
                    isPlaying = false
                    self.flutterEventSink?(["name":"onPause"])
                    break
                    
                case AVPlayer.TimeControlStatus.playing:
                    isPlaying = true
                    self.flutterEventSink?(["name":"onPlay"])
                    break
                    
                case .waitingToPlayAtSpecifiedRate: break
                @unknown default:
                    break
                }
                
            } else {
                super.observeValue(forKeyPath: keyPath,
                                   of: object,
                                   change: change,
                                   context: context)
                return
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
        
        isPlaying = false
        
        self.flutterEventSink?(["name":"onError", "error":String(data: errorMessage, encoding: .utf8)])
    }

    @objc func onAVPlayerFailedToPlayToEndTime(_ notification: Notification) {
        guard let error = notification.userInfo!["AVPlayerItemFailedToPlayToEndTimeErrorKey"] else {
            return
        }
        isPlaying = false
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
    
    private func setupNowPlayingInfoPanel() {
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = self.title
        
        nowPlayingInfo[MPMediaItemPropertyArtist] = self.subtitle
        
        if #available(iOS 10.0, *) {
            nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = self.isLiveStream
        }

        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player?.currentTime().seconds

        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player?.currentItem?.asset.duration.seconds

        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0 // will be set to 1 by onTime callback

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func updateInfoPanelOnPause() {
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds((self.player?.currentTime())!)
        
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func updateInfoPanelOnPlay() {
        
        self.nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(((self.player?.currentTime())!))
        
        self.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = self.nowPlayingInfo
    }
    
    private func updateInfoPanelOnComplete() {
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0

        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func updateInfoPanelOnTime() {
        
        self.nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds((self.player?.currentTime())!)
        
        self.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = self.nowPlayingInfo
    }
    
    @objc private func play() {
        
        player?.play()
        
        updateInfoPanelOnPlay()
        
        onDurationChange()
    }
    
    private func pause() {
        
        player?.pause()
        
        updateInfoPanelOnPause()
        
        onDurationChange()
    }
    
    private func onTimeInterval(time:CMTime) {
        
        if (isPlaying) {
            
            self.flutterEventSink?(["name":"onTime", "time":time.seconds])
            
            updateInfoPanelOnTime()
        }
        
        onDurationChange()
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
    
    private func onDurationChange() {
        
        guard let player = self.player else { return }
        
        guard let item = player.currentItem else { return }
        
        let newDuration = item.asset.duration.seconds * 1000
        
        if (newDuration.isNaN) {
            
            self.mediaDuration = newDuration
            
            self.flutterEventSink?(["name":"onDuration", "duration":-1])
            
        } else if (newDuration != mediaDuration) {
            
            self.mediaDuration = newDuration
            
            self.flutterEventSink?(["name":"onDuration", "duration":self.mediaDuration])
        }
    }
    
    public func dispose() {
        
        self.player?.pause()
        
        /* clear lock screen metadata */
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        
        /* remove observers */
        if let timeObserver = timeObserverToken {
            player?.removeTimeObserver(timeObserver)
            timeObserverToken = nil
        }
        
        /* stop audio session */
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false)
        } catch _ { }
        
        NotificationCenter.default.removeObserver(self)
        
        self.player?.flutterEventSink = nil
        
        self.flutterEventSink = nil
        self.eventChannel?.setStreamHandler(nil)
        
        self.player = nil
    }
    
    /**
     detach player UI to keep audio playing in background
     */
    func applicationDidEnterBackground(_ application: UIApplication) {
        self.playerViewController?.player = nil
    }
    
    /**
     reattach player UI as app is in foreground now
     */
    func applicationWillEnterForeground(_ application: UIApplication) {
        self.playerViewController?.player = self.player
    }
}

