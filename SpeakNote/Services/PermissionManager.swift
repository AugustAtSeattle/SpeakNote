//
//  PermissionManager.swift
//  SpeakNote
//
//  Created by Sailor on 12/26/23.
//

import Foundation
import Speech

class PermissionManager {
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
    
    // Wrap the microphone permission request in an async function
    func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    continuation.resume(returning: granted)
                }
            }
        }
    }
         
    // Wrap the speech recognition permission request in an async function
    func requestSpeechRecognitionPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { authStatus in
                DispatchQueue.main.async {
                    continuation.resume(returning: authStatus == .authorized)
                }
            }
        }
    }
}
