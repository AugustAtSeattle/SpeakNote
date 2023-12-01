//
//  SpeechViewModel.swift
//  SpeakNote
//
//  Created by Sailor on 11/27/23.
//

import Foundation
import Speech
import RxSwift
import RxCocoa

class SpeechViewModel: NSObject, SFSpeechRecognizerDelegate  {
    private let disposeBag = DisposeBag()
    private let speechManager = SpeechRecognitionManager()

    // Relay for the listening state, initialized with `false`.
    let isListeningRelay = BehaviorRelay<Bool>(value: false)
    
    // Public computed property to get the current listening state.
    var isListening: Bool {
        return isListeningRelay.value
    }
    
    // Relay for the transcribed text, initialized with an empty string.
    let transcribedText = BehaviorRelay<String>(value: "")
    
    override init() {
        super.init()
        setupSpeechManager()
    }

    private func setupSpeechManager() {

        // Set up the callback for speech recognition results
        speechManager.onResult = { [weak self] result in
            self?.transcribedText.accept(result)
        }

        // Optionally, handle errors if your speechManager provides such a callback
        speechManager.onError = { error in
            // Handle any errors
        }
        
        // Set up the callback for listening status changes
        speechManager.onListeningStatusChanged = { [weak self] isListening in
            self?.isListeningRelay.accept(isListening)
        }
    }
    
    func toggleListening() {
        if isListeningRelay.value {
            stopListening()
        } else {
            startListening()
        }
    }

    func startListening() {
        speechManager.startRecognition()
    }


    func stopListening() {
        speechManager.stopRecognition()
    }

    
    func requestSpeechRecognitionPermission() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("Speech recognition authorization granted")
                    // You can now proceed with speech recognition

                case .denied:
                    print("Speech recognition authorization denied")
                    // Handle the denied case

                case .restricted:
                    print("Speech recognition not available on this device")
                    // Handle the restricted case

                case .notDetermined:
                    print("Speech recognition authorization not determined")
                    // Handle the not determined case

                @unknown default:
                    print("Unknown authorization status")
                    // Handle potential future cases
                }
            }
        }
    }
}
