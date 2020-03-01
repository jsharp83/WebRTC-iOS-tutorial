//
//  Config.swift
//  WebRTCTutorial
//
//  Created by Eric on 2020/03/01.
//  Copyright © 2020 Eric. All rights reserved.
//

import Foundation

// Set this to the machine's address which runs the signaling server
fileprivate let defaultSignalingServerUrl = URL(string: "ws://developereric.com:8080")!

// We use Google's public stun servers. For production apps you should deploy your own stun/turn servers.
fileprivate let defaultIceServers = ["stun:stun.l.google.com:19302",
                                     "stun:stun1.l.google.com:19302",
                                     "stun:stun2.l.google.com:19302",
                                     "stun:stun3.l.google.com:19302",
                                     "stun:stun4.l.google.com:19302"]

fileprivate let defaultServerURLPath = "https://appr.tc"

struct Config {
    let signalingServerUrl: URL
    let serverURLPath: String
    let webRTCIceServers: [String]
    
    static let `default` = Config(signalingServerUrl: defaultSignalingServerUrl,
                                  serverURLPath: defaultServerURLPath,
                                  webRTCIceServers: defaultIceServers)
}
