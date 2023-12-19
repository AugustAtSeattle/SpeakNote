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
import MessageKit

struct SenderViewModel: SenderType {
    var senderId: String
    var displayName: String
}

struct MessageViewModel: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}

class SpeechViewModel: NSObject, SFSpeechRecognizerDelegate {
    private let disposeBag = DisposeBag()
    private let speechManager = SpeechRecognitionManager()
    private let assistant = AssistantClient()
    private let databaseManager = DatabaseManager.shared
    private let appleSpeechService = AppleSpeechService()

    // Inputs
    // let toggleListening: AnyObserver<Void>

    // Outputs
    let transcribedText = BehaviorRelay<String>(value: "Press the button and start speaking")
    let recordsText = BehaviorRelay<String>(value: "")
    let isListeningRelay = BehaviorRelay<Bool>(value: false)
    let isLoadingFromServerRelay = BehaviorRelay<Bool>(value: false)
    let messages = BehaviorRelay<[MessageType]>(value: [])

    let currentSender: SenderType = SenderViewModel(senderId: "user", displayName: "User")
    let assistantSender: SenderType = SenderViewModel(senderId: "assistant", displayName: "Assistant")
    
    // Public computed property to get the current listening state.
    var isListening: Bool {
        return isListeningRelay.value
    }
    
    // Relay for the error state, initialized with nil.
    let errorRelay = BehaviorRelay<Error?>(value: nil)
    // Public computed property to get the current error state.
    var error: Error? {
        return errorRelay.value
    }
    
    enum speechViewModelError: Error {
        case noTranscribedText
    }
    
    override init() {
        super.init()
        setupSpeechManager()
//        loadMessages()
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
            let messageContent = try await getMessageContent()
            _ = try await assistant.createMessage(messageContent: messageContent)
            let run = try await assistant.createRun()
            let runStatus = try await checkRunStatus(run: run)
            let latestMessage = try await assistant.readLatestMessageFromThread()
            await processLatestMessage(latestMessage: latestMessage)
        } catch {
            isLoadingFromServerRelay.accept(false)
            print(error)
        }
    }
    
    func getMessageContent() async throws -> String {
        guard !transcribedText.value.isEmpty else {
            throw speechViewModelError.noTranscribedText
        }
        
        let message: MessageType = MessageViewModel(sender: SenderViewModel(senderId: "user", displayName: "User"), messageId: UUID().uuidString, sentDate: Date(), kind: .text(transcribedText.value))
        var currentMessages = messages.value
        currentMessages.append(message)
        messages.accept(currentMessages)
        
        isLoadingFromServerRelay.accept(true)

        return transcribedText.value
    }
        
    func checkRunStatus(run: Run) async throws -> RunStatus {
        var runStatus: RunStatus?
        repeat {
            runStatus = try await assistant.getRunStatus(runId: run.id)
            guard runStatus == .queued ||
                    runStatus == .inProgress ||
                    runStatus == .completed else {
                throw AssistantClientError.openAIServiceError(message: runStatus?.rawValue ?? "Unknown error")
            }
            
            if let status = runStatus, status != .completed {
                try await Task.sleep(nanoseconds: 1_000_000_000) // sleep for 1 second before next status check
            }
        } while runStatus != .completed
        return runStatus!
    }
        
    func processLatestMessage(latestMessage: Message?) async {
        guard let latestMessage = latestMessage else {
            print("No SQL query found in the message")
            return
        }
        
        if let response = assistant.extractAssistantResponse(from: latestMessage.content.first?.text?.value) {
            let query = response.query
            let description = response.description
            databaseManager.executeQuery(query)
            let notes = databaseManager.fetchNotes()
            self.recordsText.accept(description)
            appleSpeechService.speak(text: description)
            
            let message: MessageType = MessageViewModel(sender: SenderViewModel(senderId: "assistant", displayName: "Assistant"), messageId: UUID().uuidString, sentDate: Date(), kind: .text(description))
            var currentMessages = messages.value
            currentMessages.append(message)
            messages.accept(currentMessages)
            
            isLoadingFromServerRelay.accept(false)
            print(notes)
        } else {
            print("No SQL query found in the message")
        }
    }
    
    // Load some sample messages
    func loadMessages() {
        let message1: MessageType = MessageViewModel(sender: SenderViewModel(senderId: "user", displayName: "User"), messageId: UUID().uuidString, sentDate: Date(), kind: .text("buy two eggs from Costco"))
        let message2: MessageType = MessageViewModel(sender: SenderViewModel(senderId: "assistant", displayName: "Assistant"), messageId: UUID().uuidString, sentDate: Date(), kind: .text("noted, you will buy two eggs from Costco"))
        let message3: MessageType = MessageViewModel(sender: SenderViewModel(senderId: "user", displayName: "User"), messageId: UUID().uuidString, sentDate: Date(), kind: .text("have a meetting tomorrow 10"))
        let message4: MessageType = MessageViewModel(sender: SenderViewModel(senderId: "assistant", displayName: "Assistant"), messageId: UUID().uuidString, sentDate: Date(), kind: .text("noted, you will have a meeting tomorrow at 10 am"))

        messages.accept([message1, message2, message3, message4]) // Changed to use .accept() method of BehaviorRelay
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
