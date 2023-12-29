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
    
    private let appleSpeechService = AppleSpeechService()
    private let permissionManager = PermissionManager()
    private let queryProcessingService = QueryProcessingService()
    
    // Inputs
    // let toggleListening: AnyObserver<Void>
    
    // Outputs
    let transcribedText = BehaviorRelay<String>(value: "Press the button and start speaking")
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
        permissionManager.checkAndRequestPermissions { [weak self] permissionsGranted in
            if permissionsGranted {
                self?.handleListeningState()
            } else {
                self?.presentResult("Permissions are not granted.")
            }
        }
    }
    
    private func handleListeningState() {
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
        Task {
            await performQuery()
        }
        speechManager.stopRecognition()
    }
    
    
}

// MARK: - performQuery
extension SpeechViewModel {
    
    func performQuery() async {
        do {
            let userQuery = try await getUserQuery()
            updateUIWithNewMessage(userQuery)
            let result = try await queryProcessingService.processQuery(userQuery)
            presentResult(result)
        } catch {
            handleQueryError(error)
        }
    }
    
    func getUserQuery() async throws -> String {
        guard !transcribedText.value.isEmpty else {
            throw speechViewModelError.noTranscribedText
        }
        return transcribedText.value
    }

    func updateUIWithNewMessage(_ messageContent: String) {
        let message: MessageType = MessageViewModel(sender: SenderViewModel(senderId: "user", displayName: "User"), messageId: UUID().uuidString, sentDate: Date(), kind: .text(messageContent))
        var currentMessages = messages.value
        currentMessages.append(message)
        messages.accept(currentMessages)
        
        isLoadingFromServerRelay.accept(true)
    }

    
    private func presentResult(_ description: String)  {
        appleSpeechService.speak(text: description)
        let message: MessageType = MessageViewModel(sender: SenderViewModel(senderId: "assistant", displayName: "Assistant"), messageId: UUID().uuidString, sentDate: Date(), kind: .text(description))
        var currentMessages = messages.value
        currentMessages.append(message)
        messages.accept(currentMessages)
        isLoadingFromServerRelay.accept(false)
    }
    
    private func handleQueryError(_ error: Error) {
        if let assistantError = error as? AssistantClientError {
            handleAssistantError(assistantError)
        } else if let queryError = error as? QueryError {
            handleQueryError(queryError)
        } else {
            handleGenericError(error)
        }
        print(error)
    }
    
    // Load some sample messages
    func loadMessages() {
        let message1: MessageType = MessageViewModel(sender: SenderViewModel(senderId: "user", displayName: "User"), messageId: UUID().uuidString, sentDate: Date(), kind: .text("buy two eggs from Costco"))
        let message2: MessageType = MessageViewModel(sender: SenderViewModel(senderId: "assistant", displayName: "Assistant"), messageId: UUID().uuidString, sentDate: Date(), kind: .text("noted, you will buy two eggs from Costco"))
        let message3: MessageType = MessageViewModel(sender: SenderViewModel(senderId: "user", displayName: "User"), messageId: UUID().uuidString, sentDate: Date(), kind: .text("have a meetting tomorrow 10"))
        let message4: MessageType = MessageViewModel(sender: SenderViewModel(senderId: "assistant", displayName: "Assistant"), messageId: UUID().uuidString, sentDate: Date(), kind: .text("noted, you will have a meeting tomorrow at 10 am"))
        
        messages.accept([message1, message2, message3, message4]) // Changed to use .accept() method of BehaviorRelay
    }
}

// MARK: -- Error handling enhancement: More detailed error handling and logging
extension SpeechViewModel {
    
    // Error handling enhancement: More detailed error handling and logging
    private func handleSpeechError(_ error: Error) {
        let detailedErrorDescription = "Speech Error: \(error.localizedDescription)"
        print(detailedErrorDescription) // Logging for debugging
        errorRelay.accept(error)
        presentResult("Error encountered: \(detailedErrorDescription)")
    }
    
    private func handleQueryError(_ error: QueryError) {
        // Specific error handling for QueryError
        presentResult("Query Error: \(error.localizedDescription)")
    }
    
    // Handle different types of errors with specific messages
    private func handleAssistantError(_ error: AssistantClientError) {
        // Specific error handling for AssistantClientError
        presentResult("Assistant Error: \(error.localizedDescription)")
    }
    
    private func handleGenericError(_ error: Error) {
        // Generic error handling
        presentResult("An unexpected error occurred: \(error.localizedDescription)")
    }
    
}
