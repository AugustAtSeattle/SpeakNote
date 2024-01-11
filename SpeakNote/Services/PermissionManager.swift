//
//  PermissionManager.swift
//  SpeakNote
//
//  Created by Sailor on 12/26/23.
//

import Foundation
import Speech

protocol PermissionManagerProtocol {
    func checkAndRequestPermissions() async -> Bool
    func requestSpeechAndMicrophonePermissions() async -> Bool
    func requestMicrophonePermission() async -> Bool
    func requestSpeechRecognitionPermission() async -> Bool
}

class PermissionManager: PermissionManagerProtocol {
    func checkAndRequestPermissions() async -> Bool {
        let speechRecognizerAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
        let microphoneAuthorized = AVAudioSession.sharedInstance().recordPermission == .granted
        
        if !speechRecognizerAuthorized || !microphoneAuthorized {
            return await requestMicrophonePermission()
        } else {
            return true
        }
    }
    
    func requestSpeechAndMicrophonePermissions() async -> Bool {
        let isSpeechAuthorized = await requestSpeechRecognitionPermission()
        guard isSpeechAuthorized else { return false }

        let isMicrophoneAuthorized = await requestMicrophonePermission()
        return isMicrophoneAuthorized
    }
    
    func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
         
    func requestSpeechRecognitionPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { authStatus in
                continuation.resume(returning: authStatus == .authorized)
            }
        }
    }
}
