//
//  SpeechRecognitionManager.swift
//  SpeakNote
//
//  Created by Sailor on 11/30/23.
//

import Foundation

enum SpeechRecognitionHandlerType {
    case whisper
    case apple
    case thirdParty // Placeholder for a third type
}

protocol SpeechRecognitionService {
    var onResult: ((String) -> Void)? { get set }
    var onError: ((Error) -> Void)? { get set }
    var onListeningStatusChanged: ((Bool) -> Void)? { get set }
    func startRecognition()
    func stopRecognition()
}

class SpeechRecognitionManager: SpeechRecognitionService {
    private var services: [SpeechRecognitionService] = []
    private var activeService: SpeechRecognitionService?

    init() {
        services.append(WhisperRecognitionService())
        services.append(AppleSpeechRecognitionService())
        // Add more services as needed
        
        // Set the default or preferred service
        setActiveService(serviceType: .apple)
    }

    func setActiveService(serviceType: SpeechRecognitionHandlerType) {
        switch serviceType {
        case .whisper:
            activeService = services.first { $0 is WhisperRecognitionService }
        case .apple:
            activeService = services.first { $0 is AppleSpeechRecognitionService }
        case .thirdParty:
            break
        }
    }

    var onResult: ((String) -> Void)? {
        didSet {
            activeService?.onResult = onResult
        }
    }

    var onError: ((Error) -> Void)? {
        didSet {
            activeService?.onError = onError
        }
    }
    
    var onListeningStatusChanged: ((Bool) -> Void)? {
        didSet {
            activeService?.onListeningStatusChanged = onListeningStatusChanged
        }
    }

    func startRecognition() {
        activeService?.startRecognition()
    }

    func stopRecognition() {
        activeService?.stopRecognition()
    }
}
