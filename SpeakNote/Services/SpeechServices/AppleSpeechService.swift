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
        let modifiedText = prepareTextForSpeech(text: text)

        let utterance = AVSpeechUtterance(string: modifiedText)

        // Adjust the speaking rate (value between 0.0 and 1.0)
        utterance.rate = 0.5 // Example rate, adjust as needed

        // Adjust the pitch (value between 0.5 and 2.0)
        utterance.pitchMultiplier = 1.6 // Example pitch, adjust as needed

        // Select a voice that sounds the most natural
        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }

        speechSynthesizer.speak(utterance)
    }
    
    func prepareTextForSpeech(text: String) -> String {
        var modifiedText = text
        modifiedText = modifiedText.replacingOccurrences(of: "[SHORT_PAUSE]", with: ",")
        modifiedText = modifiedText.replacingOccurrences(of: "[LONG_PAUSE]", with: ";")
        modifiedText = modifiedText.replacingOccurrences(of: "[LONG_PAUSE]", with: ".")
        modifiedText = modifiedText.replacingOccurrences(of: "[EXCLAMATION]", with: "!")
        // Add more placeholders and replacements as needed
        return modifiedText
    }


    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
}
