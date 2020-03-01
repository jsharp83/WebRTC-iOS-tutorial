//
//  VideoCallViewController.swift
//  WebRTCTutorial
//
//  Created by Eric on 2020/03/05.
//  Copyright © 2020 Eric. All rights reserved.
//

import UIKit
import AVFoundation
import WebRTC

class VideoCallViewController: UIViewController {
    var webRTCClient: WebRTCClient?
    @IBOutlet weak var localVideoView: UIView!
    @IBOutlet weak var remoteVideoView: UIView!
    
    var cameraManager: CameraManager?
    var currentSceneImage: UIImage?
    
    class func instance() -> VideoCallViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
       
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "VideoCallViewController") as? VideoCallViewController else {
            fatalError("Couldn't instantiate view controller with identifier")
        }
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        cameraManager?.delegate = self
    }
        
    private func setupView() {
        guard let webRTCClient = webRTCClient else { return }
        
        #if arch(arm64)
            // Using metal (arm64 only)
            let localRenderer = RTCMTLVideoView(frame: self.localVideoView.frame)
            let remoteRenderer = RTCMTLVideoView(frame: self.remoteVideoView.frame)
            localRenderer.videoContentMode = .scaleAspectFill
            remoteRenderer.videoContentMode = .scaleAspectFill
                
        #else
            // Using OpenGLES for the rest
            let localRenderer = RTCEAGLVideoView(frame: self.localVideoView.frame)
            let remoteRenderer = RTCEAGLVideoView(frame: self.remoteVideoView.frame)
        #endif
        
        webRTCClient.setupLocalRenderer(localRenderer)
        webRTCClient.setupRemoteRenderer(remoteRenderer)
        
        if let localVideoView = self.localVideoView {
            self.embedView(localRenderer, into: localVideoView)
        }
        self.embedView(remoteRenderer, into: remoteVideoView)
    }
}

// MARK: Camera
extension VideoCallViewController: CameraCaptureDelegate {
    func captureVideoOutput(sampleBuffer: CMSampleBuffer) {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let rtcpixelBuffer = RTCCVPixelBuffer(pixelBuffer: pixelBuffer)
            let timeStampNs: Int64 = Int64(CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)) * 1000000000)
            let videoFrame = RTCVideoFrame(buffer: rtcpixelBuffer, rotation: RTCVideoRotation._0, timeStampNs: timeStampNs)
            
            webRTCClient?.didCaptureLocalFrame(videoFrame)
        }
    }
}
