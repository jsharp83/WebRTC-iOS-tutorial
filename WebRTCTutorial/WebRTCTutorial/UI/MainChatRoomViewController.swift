//
//  ViewController.swift
//  WebRTCTutorial
//
//  Created by Eric on 2020/03/01.
//  Copyright © 2020 Eric. All rights reserved.
//

import UIKit
import AVFoundation

class MainChatRoomViewController: UIViewController {
    // MARK: Properties for room.
    @IBOutlet weak var roomNumberTextField: UITextField!
    @IBOutlet weak var stateTextView: UITextView!
    @IBOutlet weak var joinButton: UIButton!
    @IBOutlet weak var preview: UIImageView!
    @IBOutlet weak var containerView: UIView!
        
    var roomClient: RoomClient?
    var roomInfo: JoinResponseParam? {
        didSet {
            DispatchQueue.main.async {
                self.joinButton.isSelected = self.isConnected
            }
        }
    }
    
    var isConnected: Bool {
        return roomInfo != nil
    }
    
    var isInitiator: Bool {
        return roomInfo?.is_initiator == "true"
    }
    
    // MARK: Properties for Signaling
    var webSocket: WebSocketClient?
    var messageQueue = [String]()
    
    // MARK: Properties for calling
    var webRTCClient: WebRTCClient?
    let cameraManager = CameraManager()
    var videoCallVC: VideoCallViewController?
        
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraManager.startCapture()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cameraManager.stopCapture()
    }
        
    // MARK: UI Actions
    @IBAction func join(_ sender: Any) {
        guard let roomID = roomNumberTextField.text,
            roomID.isEmpty == false else {
                append(log: "You should input room number.")
                return
        }
        
        if isConnected {
            disconnect()
        } else {
            prepare()
            requestJoin(roomID)
        }
        
        roomNumberTextField.resignFirstResponder()
    }
    
    func prepare() {
        roomClient = RoomClient()
        webRTCClient = WebRTCClient()
        webSocket = WebSocketClient()
        
        let vc = VideoCallViewController.instance()
        vc.webRTCClient = webRTCClient
        vc.cameraManager = cameraManager
        addChild(vc)
        embedView(vc.view, into: containerView)
        videoCallVC = vc
    }
    
    func clear() {
        roomClient = nil
        webRTCClient = nil
        webSocket = nil
        
        videoCallVC?.removeFromParent()
        videoCallVC?.view.removeFromSuperview()
        videoCallVC = nil
        
        cameraManager.delegate = self
    }
}

// MARK: Network
extension MainChatRoomViewController {
    func requestJoin(_ roomID: String) {
        guard let roomClient = roomClient else {
            dLog("Check room client initialize part.")
            return
        }
        
        roomClient.join(roomID: roomID) { [weak self](response, error) in
            if let response = response {
                self?.append(log: "Successfully join to room.")
                self?.roomInfo = response
                if let messages = response.messages {
                    self?.handleMessages(messages)
                }
                self?.connectToWebSocket()
            } else if let error = error as? RoomResponseError,
                error == .full {
                self?.append(log: "Room is full. Use different room number.")
            } else if let error = error {
                self?.append(log: error.localizedDescription)
            }
        }
    }
        
    func disconnect() {
        guard let roomID = roomInfo?.room_id,
            let userID = roomInfo?.client_id,
            let roomClient = roomClient,
            let webSocket = webSocket,
            let webRTCClient = webRTCClient else { return }
        
        roomClient.disconnect(roomID: roomID, userID: userID) { [weak self] in
            self?.roomInfo = nil
            self?.append(log: "Disconnected.")
        }
        
        let message = ["type": "bye"]
        
        if let data = message.JSONData {
            webSocket.send(data: data)
        }
                
        webSocket.delegate = nil
        roomInfo = nil

        webRTCClient.disconnect()
        
        clear()
    }
    
    func handleMessages(_ messages: [String]) {
        messageQueue.append(contentsOf: messages)
        drainMessageQueue()
    }
    
    func drainMessageQueue() {
        guard let webSocket = webSocket,
            webSocket.isConnected,
            let webRTCClient = webRTCClient else {
                return
        }
        
        for message in messageQueue {
            handleMessage(message)
        }
        messageQueue.removeAll()
        webRTCClient.drainMessageQueue()
    }
    
    func handleMessage(_ message: String) {
        guard let webRTCClient = webRTCClient else { return }
        
        let signalMessage = SignalMessage.from(message: message)
        switch signalMessage {
        case .candidate(let candidate):
            webRTCClient.handleCandidateMessage(candidate)
            append(log: "Receive candidate")
        case .answer(let answer):
            webRTCClient.handleRemoteDescription(answer)
            append(log: "Recevie Answer")
        case .offer(let offer):
            webRTCClient.handleRemoteDescription(offer)
            append(log: "Recevie Offer")
        case .bye:
            disconnect()
        default:
            break
        }
    }
    
    func sendSignalingMessage(_ message: Data) {
        guard let roomID = roomInfo?.room_id,
            let userID = roomInfo?.client_id,
            let roomClient = roomClient else { return }
        
        roomClient.sendMessage(message, roomID: roomID, userID: userID) { [weak self] in
            self?.append(log: "Send signal message successfully")
        }
    }
}

// MARK: WebSocket
extension MainChatRoomViewController: WebSocketClientDelegate {
    func connectToWebSocket() {
        guard let webSocketURLPath = roomInfo?.wss_url,
            let url = URL(string: webSocketURLPath),
            let webSocket = webSocket else {
                append(log: "Fail to connect websocket for signaling")
                return
        }

        webSocket.delegate = self
        webSocket.connect(url: url)
    }
    
    func registerRoom() {
        guard let roomID = roomInfo?.room_id,
            let userID = roomInfo?.client_id,
            let webSocket = webSocket else {
                append(log: "RoomID or UserID is empty. Should be check.")
                return
        }
        
        let message = ["cmd": "register",
                       "roomid": roomID,
                       "clientid": userID
        ]
        
        guard let data = message.JSONData else {
            debugPrint("Error in Register room.")
            return
        }
                
        webSocket.send(data: data)
        dLog("Register Room")
    }
    
    func webSocketDidConnect(_ webSocket: WebSocketClient) {
        guard let webRTCClient = webRTCClient else { return }
        
        append(log: "Successfully connect to websocket")
        registerRoom()
        
        webRTCClient.delegate = self
        
        if isInitiator {
            webRTCClient.offer()
        }
        
        drainMessageQueue()
    }
    
    func webSocketDidDisconnect(_ webSocket: WebSocketClient) {
        webSocket.delegate = nil
        append(log: "Disconnect to websocket")
    }
    
    func webSocket(_ webSocket: WebSocketClient, didReceive data: String) {
        append(log: "Receive data from websocket")
        dLog("Received data from websocket \(data)")

        handleMessage(data)
        
        webRTCClient?.drainMessageQueue()
    }
}

extension MainChatRoomViewController: WebRTCClientDelegate {
    func webRTCClient(_ client: WebRTCClient, sendData data: Data) {
        sendSignalingMessage(data)
    }
}

// MARK: Handle camera and show preview
extension MainChatRoomViewController: CameraCaptureDelegate {
    func setupCamera() {
        cameraManager.delegate = self
        cameraManager.setupCamera()
    }

    func captureVideoOutput(sampleBuffer: CMSampleBuffer) {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let ciImage = CIImage(cvImageBuffer: pixelBuffer)
            let image = UIImage(ciImage: ciImage)
            DispatchQueue.main.async {
                self.preview.image = image
            }
        }
    }
}

// MARK: Handle Log
extension MainChatRoomViewController {
    func append(log: String) {
        DispatchQueue.main.async {
            self.stateTextView.text = self.stateTextView.text + "\n" + log
        }
    }
}
