//
//  RTCSessionDescription+Ext.swift
//  WebRTCTutorial
//
//  Created by Eric on 2020/03/05.
//  Copyright © 2020 Eric. All rights reserved.
//

import Foundation
import WebRTC

extension RTCSessionDescription {
    func JSONData() -> Data? {
        let typeStr = RTCSessionDescription.string(for: self.type)
        let dict = ["type": typeStr,
                    "sdp": self.sdp]
        return dict.JSONData
    }
}

extension RTCIceCandidate {
    func JSONData() -> Data? {
        let dict = ["type": "candidate",
                    "label": "\(self.sdpMLineIndex)",
                    "id": self.sdpMid,
                    "candidate": self.sdp
        ]
        return dict.JSONData
    }

    static func candidate(from: [String: Any]) -> RTCIceCandidate? {
        let sdp = from["candidate"] as? String
        let sdpMid = from["id"] as? String
        let labelStr = from["label"] as? String
        let label = (from["label"] as? Int32) ?? 0
        
        return RTCIceCandidate(sdp: sdp ?? "", sdpMLineIndex: Int32(labelStr ?? "") ?? label, sdpMid: sdpMid)
    }
}

