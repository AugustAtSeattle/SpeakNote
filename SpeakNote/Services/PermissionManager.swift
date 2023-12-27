//
//  PermissionManager.swift
//  SpeakNote
//
//  Created by Sailor on 12/26/23.
//

import Foundation
import Speech

class PermissionManager {
    func checkAndRequestPermissions(completion: @escaping (Bool) -> Void) {
        let speechRecognizerAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
        let microphoneAuthorized = AVAudioSession.sharedInstance().recordPermission == .granted
        
        if !speechRecognizerAuthorized || !microphoneAuthorized {
            requestSpeechAndMicrophonePermissions(completion: completion)
        } else {
            completion(true)
        }
    }
    
    func requestSpeechAndMicrophonePermissions(completion: @escaping (Bool) -> Void) {
         requestSpeechRecognitionPermission { speechGranted in
             if speechGranted {
                 self.requestMicrophonePermission(completion: completion)
             } else {
                 completion(false)
             }
         }
     }
     
     func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
         AVAudioSession.sharedInstance().requestRecordPermission { granted in
             DispatchQueue.main.async {
                 if granted {
                     print("Microphone permission granted")
                 } else {
                     print("Microphone permission denied")
                 }
                 completion(granted)
             }
         }
     }
     
     func requestSpeechRecognitionPermission(completion: @escaping (Bool) -> Void) {
         SFSpeechRecognizer.requestAuthorization { authStatus in
             DispatchQueue.main.async {
                 switch authStatus {
                 case .authorized:
                     print("Speech recognition authorization granted")
                     completion(true)
                     
                 case .denied, .restricted, .notDetermined:
                     print("Speech recognition authorization denied, restricted, or not determined")
                     // Optionally, show an alert or update the UI to inform the user
                     completion(false)
                     
                 @unknown default:
                     print("Unknown authorization status")
                     completion(false)
                 }
             }
         }
     }
}
