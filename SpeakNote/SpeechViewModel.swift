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
    private let assistant = AssistantClient()

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
        let speechRecognizerAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
        let microphoneAuthorized = AVAudioSession.sharedInstance().recordPermission == .granted

        // If either permission is not granted, request them and then return immediately
        if !speechRecognizerAuthorized || !microphoneAuthorized {
            requestSpeechAndMicrophonePermissions { _ in
                // Do nothing
            }
        } else {
            // If permissions are already granted, proceed with toggling listening
            if isListeningRelay.value {
                stopListening()
            } else {
                startListening()
            }
        }
    }

    func startListening() {
        speechManager.startRecognition()
    }


    func stopListening() {
        speechManager.stopRecognition()
        Task{
            do {
//                let message = try await assistant.createMessage(messageContent: "Get a birthday cake before 5")
//                let message = try await assistant.readLatestMessageFromThread()
//                let run = try await assistant.createRun()
//                print(run)
//                if run.status == "queued" {
                    let message = try await assistant.readLatestMessageFromThread()
                    print("message: \(message)")
//                }
//            message: Optional(SpeakNote.Message(id: "msg_ifRa1Uaupt9KSpHtgfOiXTFf", object: "thread.message", createdAt: 1702258096, threadId: "44", role: "assistant", content: [SpeakNote.Content(type: "text", text: Optional(SpeakNote.Text(value: "{\n  \"query\": \"INSERT INTO notes (subject, details, createDate, deadline, category, status) VALUES (\'Get Birthday Cake\', \'Get a birthday cake before 5 PM\', CURRENT_TIMESTAMP, DATE(\'now\'), \'Personal\', \'Pending\')\"\n}", annotations: Optional([]))))], assistantId: Optional("44"), runId: Optional("33"), metadata: Optional([:])))
            } catch {
                print(error)
            }
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
