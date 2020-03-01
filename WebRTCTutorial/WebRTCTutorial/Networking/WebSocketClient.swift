//
//  WebSocketClient.swift
//  WebRTCTutorial
//
//  Created by Eric on 2020/03/05.
//  Copyright © 2020 Eric. All rights reserved.
//

import Foundation
import SocketRocket

protocol WebSocketClientDelegate: class {
    func webSocketDidConnect(_ webSocket: WebSocketClient)
    func webSocketDidDisconnect(_ webSocket: WebSocketClient)
    func webSocket(_ webSocket: WebSocketClient, didReceive data: String)
}

class WebSocketClient: NSObject {
    weak var delegate: WebSocketClientDelegate?
    var socket: SRWebSocket?
    
    var isConnected: Bool {
        return socket != nil
    }
    
    func connect(url: URL) {
        socket = SRWebSocket(url: url)
        socket?.delegate = self
        socket?.open()
    }
    
    func disconnect() {
        socket?.close()
        socket = nil
        self.delegate?.webSocketDidDisconnect(self)
    }
    
    func send(data: Data) {
        guard let socket = socket else {
            dLog("Check Socket connection")
            return
        }
        
        dLog(data.prettyPrintedJSONString)
        socket.send(data)
    }
}

extension WebSocketClient: SRWebSocketDelegate {
    func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
        dLog(message)
        if let message = message as? String {
            delegate?.webSocket(self, didReceive: message)
        }
    }
    
    func webSocketDidOpen(_ webSocket: SRWebSocket!) {
        delegate?.webSocketDidConnect(self)
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {
        debugPrint("did Fail to connect websocket")
        self.disconnect()
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        debugPrint("did close websocket")
        self.disconnect()
    }
}
