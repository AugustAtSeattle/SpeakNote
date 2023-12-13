//
//  AppleSpeechService.swift
//  SpeakNote
//
//  Created by Sailor on 12/12/23.
//

import Foundation
import AVFoundation

protocol SpeechService {
    func speak(text: String)
}

class AppleSpeechService: SpeechService {
    private let speechSynthesizer = AVSpeechSynthesizer()

    func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        speechSynthesizer.speak(utterance)
    }

    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
}
