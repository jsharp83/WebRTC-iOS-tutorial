//
//  CameraManager.swift
//  WebRTCTutorial
//
//  Created by Eric on 2020/03/05.
//  Copyright © 2020 Eric. All rights reserved.
//

import Foundation
import AVFoundation

@objc
protocol CameraCaptureDelegate: class {
    func captureVideoOutput(sampleBuffer: CMSampleBuffer)
}

class CameraManager: NSObject {
    var videoCaptureDevice: AVCaptureDevice?
    let captureSession = AVCaptureSession()
    let videoDataOutput = AVCaptureVideoDataOutput()
    let audioDataOutput = AVCaptureAudioDataOutput()
    let dataOutputQueue = DispatchQueue(label: "VideoDataQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    weak var delegate: CameraCaptureDelegate?
    
    var isCapturing = false
        
    func setupCamera() {
        guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else { return }
        
        self.videoCaptureDevice = videoCaptureDevice
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        // Add a video data output
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            videoDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
            videoDataOutput.connection(with: .video)?.videoOrientation = .portrait
            videoDataOutput.connection(with: .video)?.automaticallyAdjustsVideoMirroring = false
            videoDataOutput.connection(with: .video)?.isVideoMirrored = true
        } else {
            dLog("Could not add video data output to the session")
            captureSession.commitConfiguration()
        }
    }
    
    func startCapture() {
        dLog("Capture Start!!")
        
        guard isCapturing == false else { return }
        isCapturing = true
        
        #if arch(arm64)
        captureSession.startRunning()
        #endif
    }
    
    func stopCapture() {
        dLog("Capture Ended!!")
        guard isCapturing == true else { return }
        isCapturing = false

        #if arch(arm64)
        captureSession.stopRunning()
        #endif
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if connection == videoDataOutput.connection(with: .video) {
            delegate?.captureVideoOutput(sampleBuffer: sampleBuffer)
        }
    }
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    }
}
