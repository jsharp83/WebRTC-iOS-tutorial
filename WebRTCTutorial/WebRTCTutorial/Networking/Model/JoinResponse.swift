//
//  JoinResponse.swift
//  WebRTCTutorial
//
//  Created by Eric on 2020/03/03.
//  Copyright © 2020 Eric. All rights reserved.
//

import Foundation

enum JoinStatus: String, Decodable {
    case FULL
    case SUCCESS
}

struct JoinResponse: Decodable {
    let result: JoinStatus
    let params: JoinResponseParam
}

struct JoinResponseParam: Decodable {
    let room_id: String?
    let wss_url: String?
    let wss_post_url: String?
    let client_id: String?
    let is_initiator: String?
    let messages: [String]?
}
