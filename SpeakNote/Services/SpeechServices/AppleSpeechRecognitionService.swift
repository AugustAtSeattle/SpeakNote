//
//  AppleSpeechRecognitionService.swift
//  SpeakNote
//
//  Created by Sailor on 11/30/23.
//

import Foundation
import Speech

class AppleSpeechRecognitionService: SpeechRecognitionService {
    var onResult: ((String) -> Void)?
    var onError: ((Error) -> Void)?
    var onListeningStatusChanged: ((Bool) -> Void)?
    
    private let speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var lastTranscriptTimestamp: Date?
    private var silenceTimer: Timer?

    func startRecognition() {
        // Apple SFSpeechRecognizer implementation
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
            onListeningStatusChanged?(true)
            lastTranscriptTimestamp = Date()
            silenceTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(checkForSilence), userInfo: nil, repeats: true)
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }

    func stopRecognition() {
        // Stop Apple recognition
        // Stop the audio engine and recognition task.
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
        onListeningStatusChanged?(false)
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
//                print("Recognition task result: \(result.bestTranscription.formattedString)")
                self?.lastTranscriptTimestamp = Date()
                self?.onResult?(result.bestTranscription.formattedString) // Trigger the onResult callback if set
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
            print("Detected 15 seconds of silence")
            stopRecognition()
        }
    }
}
