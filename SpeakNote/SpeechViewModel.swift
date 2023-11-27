//
//  SpeechViewModel.swift
//  SpeakNote
//
//  Created by Sailor on 11/27/23.
//

import Foundation
import Speech

class SpeechViewModel: NSObject, SFSpeechRecognizerDelegate  {
    private let speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    
    var isListeningChanged: ((Bool) -> Void)?

    var isListening: Bool = false {
        didSet {
            isListeningChanged?(isListening)
        }
    }
    
    var transcribedText: String = "" {
        didSet {
            transcribedTextChanged?(transcribedText)
        }
    }

    var transcribedTextChanged: ((String) -> Void)?

    func startListening() {
        // Check if already running a recognition task
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        // Setup audio engine and speech recognizer
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            // Handle the error here
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else { return }

        // Configure request here, like setting contextual strings, etc.

        // Start the recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                // Update your model with the results
                self.transcribedText = result.bestTranscription.formattedString
            } else if let error = error {
                // Handle errors here
            }
        }

        // Setup and start the audio engine
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            // Handle errors here
        }

        // Indicate that listening has started
        isListening = true
    }
    
    func stopListening() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil

        // Reset audio session if necessary
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false)
        } catch {
            // Handle errors here
        }

        isListening = false
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

