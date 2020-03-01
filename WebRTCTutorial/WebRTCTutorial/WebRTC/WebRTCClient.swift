//
//  WebRTCClient.swift
//  WebRTCTutorial
//
//  Created by Eric on 2020/03/04.
//  Copyright © 2020 Eric. All rights reserved.
//

import Foundation
import WebRTC

protocol WebRTCClientDelegate: class {
    func webRTCClient(_ client: WebRTCClient, sendData data: Data)
}

class WebRTCClient: NSObject {
    static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        return RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
    }()
    private let mediaConstraints = [kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
                                   kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue]

    private var candidateQueue = [RTCIceCandidate]()
    
    private var peerConnection: RTCPeerConnection?
    private var localVideoSource: RTCVideoSource?
    private var localVideoTrack: RTCVideoTrack?
    private var videoCapturer: RTCVideoCapturer?
    private var remoteVideoTrack: RTCVideoTrack?
        
    weak var delegate: WebRTCClientDelegate?
    
    private var hasReceivedSdp = false
    
    override init() {
        super.init()
        setup()
    }
    
    func setup() {
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: ["DtlsSrtpKeyAgreement": "true"])
        let config = generateRTCConfig()

        peerConnection = WebRTCClient.factory.peerConnection(with: config, constraints: constraints, delegate: self)
        
        createMediaSenders()
        configureAudioSession()
    }
            
    func offer() {
        guard let peerConnection = peerConnection else {
            dLog("Check PeerConnection")
            return
        }
        
        dLog("WebRTC Offer.")
        peerConnection.offer(for: RTCMediaConstraints(mandatoryConstraints: mediaConstraints, optionalConstraints: nil), completionHandler: { [weak self](sdp, error) in
            guard let self = self else { return }
            
            guard let sdp = sdp else {
                if let error = error {
                    dLog(error)
                }
                return
            }
            
            self.setLocalSDP(sdp)
        })
    }
    
    private func answer() {
        guard let peerConnection = peerConnection else {
            dLog("Check PeerConnection")
            return
        }

        dLog("WebRTC Answer.")
        peerConnection.answer(for: RTCMediaConstraints(mandatoryConstraints: mediaConstraints, optionalConstraints: nil),
                               completionHandler: { [weak self](sdp, error) in
                                guard let sdp = sdp else {
                                    if let error = error {
                                        dLog(error)
                                    }
                                    return
                                }
                                self?.setLocalSDP(sdp)
        })
    }
    
    func disconnect() {
        hasReceivedSdp = false
        peerConnection?.close()
        
        peerConnection = nil
        localVideoSource = nil
        localVideoTrack = nil
        videoCapturer = nil
        remoteVideoTrack = nil
    }
    
    
    private func setLocalSDP(_ sdp: RTCSessionDescription) {
        guard let peerConnection = peerConnection else {
            dLog("Check PeerConnection")
            return
        }
        
        peerConnection.setLocalDescription(sdp, completionHandler: { (error) in
            if let error = error {
                debugPrint(error)
            }
        })
        
        if let data = sdp.JSONData() {
            self.delegate?.webRTCClient(self, sendData: data)
            dLog("Send Local SDP")
        }
    }
}

// MARK: Preparing parts.
extension WebRTCClient {
    private func generateRTCConfig() -> RTCConfiguration {
        let config = RTCConfiguration()
        let pcert = RTCCertificate.generate(withParams: ["expires": NSNumber(value: 100000),
                                                         "name": "RSASSA-PKCS1-v1_5"
        ])
        config.iceServers = [RTCIceServer(urlStrings: Config.default.webRTCIceServers)]
        config.sdpSemantics = RTCSdpSemantics.unifiedPlan
        config.certificate = pcert
        
        return config
    }
    
    private func createMediaSenders() {
        guard let peerConnection = peerConnection else {
            dLog("Check PeerConnection")
            return
        }
        
        let constraints = RTCMediaConstraints(mandatoryConstraints: [:], optionalConstraints: nil)
        let audioSource = WebRTCClient.factory.audioSource(with: constraints)
        let audioTrack = WebRTCClient.factory.audioTrack(with: audioSource, trackId: "ARDAMSa0")
        
        let mediaTrackStreamIDs = ["ARDAMS"]
        
        peerConnection.add(audioTrack, streamIds: mediaTrackStreamIDs)
        
        let videoSource = WebRTCClient.factory.videoSource()
        localVideoSource = videoSource
        let videoTrack = WebRTCClient.factory.videoTrack(with: videoSource, trackId: "ARDAMSv0")
        localVideoTrack = videoTrack
        videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        
        peerConnection.add(videoTrack, streamIds: mediaTrackStreamIDs)
                        
        remoteVideoTrack = peerConnection.transceivers.first { $0.mediaType == .video }?.receiver.track as? RTCVideoTrack
    }
    
    private func configureAudioSession() {
        let audioSession = RTCAudioSession.sharedInstance()
        
       audioSession.lockForConfiguration()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue)
            try audioSession.setMode(AVAudioSession.Mode.voiceChat.rawValue)
            try audioSession.overrideOutputAudioPort(.speaker)
            try audioSession.setActive(true)
        } catch let error {
            dLog("Error changeing AVAudioSession category: \(error)")
        }
        audioSession.unlockForConfiguration()
    }
}

// MARK: UI Handling
extension WebRTCClient {
    func setupLocalRenderer(_ renderer: RTCVideoRenderer) {
        guard let localVideoTrack = localVideoTrack else {
            dLog("Check Local Video track")
            return
        }
        
        localVideoTrack.add(renderer)
    }
    
    func setupRemoteRenderer(_ renderer: RTCVideoRenderer) {
        guard let remoteVideoTrack = remoteVideoTrack else {
            dLog("Check Remote Video track")
            return
        }
        
        remoteVideoTrack.add(renderer)
    }
    
    func didCaptureLocalFrame(_ videoFrame: RTCVideoFrame) {
        guard let videoSource = localVideoSource,
            let videoCapturer = videoCapturer else { return }
        
        videoSource.capturer(videoCapturer, didCapture: videoFrame)
    }
}

// MARK: Message Handling
extension WebRTCClient {
    func handleCandidateMessage(_ candidate: RTCIceCandidate) {
        candidateQueue.append(candidate)
    }
    
    func handleRemoteDescription(_ desc: RTCSessionDescription) {
        guard let peerConnection = peerConnection else {
            dLog("Check Peer connection")
            return
        }
        
        hasReceivedSdp = true
        
        peerConnection.setRemoteDescription(desc, completionHandler: { [weak self](error) in
            if let error = error {
                dLog(error)
            }

            if desc.type == .offer,
                self?.peerConnection?.localDescription == nil {
                self?.answer()
            }
        })
    }
        
    func drainMessageQueue() {
        guard let peerConnection = peerConnection,
            hasReceivedSdp else {
                return
        }
        
        dLog("Drain Messages")
                
        for candidate in candidateQueue {
            dLog("Add Candidate: \(candidate)")
            peerConnection.add(candidate)
        }
        
        candidateQueue.removeAll()
    }
}

extension WebRTCClient: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        dLog("\(stateChanged.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        dLog("")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        dLog("")
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        dLog("")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        dLog("\(newState.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        dLog("")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        guard let message = candidate.JSONData() else { return }
        delegate?.webRTCClient(self, sendData: message)
        dLog("")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        dLog("")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        dLog("")
    }
}
