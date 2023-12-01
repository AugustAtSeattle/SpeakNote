//
//  WhisperRecognitionService.swift
//  SpeakNote
//
//  Created by Sailor on 11/30/23.
//

import Foundation
class WhisperRecognitionService: SpeechRecognitionService {
    var onResult: ((String) -> Void)?
    var onError: ((Error) -> Void)?
    var onListeningStatusChanged: ((Bool) -> Void)?

    func startRecognition() {
        // GPT Whisper implementation
    }

    func stopRecognition() {
        // Stop Whisper recognition
    }
}
