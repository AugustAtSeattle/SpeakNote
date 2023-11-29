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
    
    private let speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var lastTranscriptTimestamp: Date?
    private var silenceTimer: Timer?

    // Relay for the listening state, initialized with `false`.
    let isListeningRelay = BehaviorRelay<Bool>(value: false)
    // Public computed property to get the current listening state.
    var isListening: Bool {
        return isListeningRelay.value
    }
    
    let transcribedText = BehaviorRelay<String>(value: "")
    
    func toggleListening() {
        let currentState = isListeningRelay.value
        if currentState {
            stopListening()
        } else {
            startListening()
        }
    }

    func startListening() {
        // Cancel any existing recognition task
        cancelExistingRecognitionTask()

        // Prepare audio engine
        prepareAudioEngine()

        // Configure and activate audio session
        guard configureAudioSession() else { return }

        // Setup and start the recognition task
        setupAndStartRecognitionTask()

        // Start audio engine
        do {
            try audioEngine.start()
            isListeningRelay.accept(true)
            lastTranscriptTimestamp = Date()
            silenceTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(checkForSilence), userInfo: nil, repeats: true)
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }

    private func cancelExistingRecognitionTask() {
        recognitionTask?.cancel()
        recognitionTask = nil
    }

    private func prepareAudioEngine() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }

    private func configureAudioSession() -> Bool {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            return true
        } catch {
            print("Audio session configuration error: \(error)")
            return false
        }
    }

    private func setupAndStartRecognitionTask() {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        let inputNode = audioEngine.inputNode
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let result = result {
                self?.lastTranscriptTimestamp = Date()
                self?.transcribedText.accept(result.bestTranscription.formattedString)
            } else if let error = error {
                print("Recognition task error: \(error)")
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
    }
    
    @objc private func checkForSilence() {
        guard let lastTimestamp = lastTranscriptTimestamp else { return }

        if Date().timeIntervalSince(lastTimestamp) >= 15 {
            // Detected 15 seconds of silence
            stopListening()
        }
    }

    func stopListening() {
        audioEngine.stop()
        // Safely remove the tap on the inputNode.
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        silenceTimer?.invalidate()
        silenceTimer = nil
        lastTranscriptTimestamp = nil
        
        // Cancel the previous task if it's running.
        if let recognitionTask = self.recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        // Reset the audio session.
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            try audioSession.setCategory(.ambient) // Set the session category to ambient to deactivate recording setup.
        } catch {
            // Handle the error more specifically if desired
            print("Audio Session error: \(error)")
        }
        
        // Notify observers that listening has stopped.
        isListeningRelay.accept(false)
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
