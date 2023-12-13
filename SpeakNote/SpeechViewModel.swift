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
    private let databaseManager = DatabaseManager.shared
    

    // Relay for the listening state, initialized with `false`.
    let isListeningRelay = BehaviorRelay<Bool>(value: false)
    
    // Public computed property to get the current listening state.
    var isListening: Bool {
        return isListeningRelay.value
    }
    
    // Relay for the transcribed text, initialized with an empty string.
    let transcribedText = BehaviorRelay<String>(value: "")
    
    // Relay for the error state, initialized with nil.
    let errorRelay = BehaviorRelay<Error?>(value: nil)

    // Public computed property to get the current error state.
    var error: Error? {
        return errorRelay.value
    }
    
    override init() {
        super.init()
        setupSpeechManager()
    }

    private func setupSpeechManager() {

        // Set up the callback for speech recognition results
        speechManager.onResult = { [weak self] result in
            self?.transcribedText.accept(result)
        }
        
        // Set up the callback for error handling
        speechManager.onError = { [weak self] error in
            self?.errorRelay.accept(error)
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
        Task {
            await performQueryHelper()
        }
        speechManager.stopRecognition()

    }

    func performQueryHelper() async {
        do {
            guard !transcribedText.value.isEmpty else {
                print("Transcribed text is empty")
                return
            }
            
            let messageContent = transcribedText.value
            let message = try await assistant.createMessage(messageContent: messageContent)
            let run = try await assistant.createRun()
            
            try await Task.sleep(nanoseconds: 10_000_000_000)
            
            let latestMessage = try await assistant.readLatestMessageFromThread()
            
            if let query = assistant.extractAssistantResponse(from: latestMessage?.content.first?.text?.value)?.query {
                databaseManager.executeQuery(query)
                let notes = databaseManager.fetchNotes()
                print(notes)
            } else {
                print("No SQL query found in the message")
            }
        } catch {
            print(error)
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
