//
//  WhisperRecognitionService.swift
//  SpeakNote
//
//  Created by Sailor on 11/30/23.
//

import Foundation
import AVFoundation

class WhisperRecognitionService: SpeechRecognitionService {
    private let networkClient = WhisperNetworkClient()
    private var audioRecorder: AVAudioRecorder?
    private var audioFileURL: URL?
    var onResult: ((String) -> Void)?
    var onError: ((Error) -> Void)?
    var onListeningStatusChanged: ((Bool) -> Void)?

    func startRecognition() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.wav")
        audioFileURL = audioFilename
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            onListeningStatusChanged?(true)
        } catch {
            onError?(error)
        }
    }

    func stopRecognition() {
        audioRecorder?.stop()
        onListeningStatusChanged?(false)
        
        guard let audioURL = audioFileURL else {
            onError?(NSError(domain: "WhisperRecognitionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Audio file URL is nil."]))
            return
        }
        
        Task {
            do {
                let transcription = try await networkClient.transcribeAudioFile(at: audioURL)
                onResult?(transcription)
            } catch {
                onError?(error)
            }
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
