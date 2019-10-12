//
//  FlutterAVPlayer.swift
//  flutter_playout
//
//  Created by Khuram Khalid on 12/10/2019.
//

import Foundation
import AVKit

class FluterAVPlayer: AVPlayer {
    var flutterEventSink:FlutterEventSink?
    
    /**
     intercept onSeek event to also send a notification back to Flutter code
     */
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
