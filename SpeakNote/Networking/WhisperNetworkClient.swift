//
//  WhisperNetworkClient.swift
//  SpeakNote
//
//  Created by Sailor on 12/1/23.
//

import Foundation

// Define errors that can occur during the networking process
enum WhisperServiceError: Error {
    case invalidResponse
    case requestFailed(Error)
    case invalidData
}

class WhisperNetworkClient {
    
    // Function to send audio data to Whisper API
    func transcribeAudioFile(at url: URL) async throws -> String {
        let request = createRequest(with: url)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw WhisperServiceError.invalidResponse
            }
            
            // Assuming the response is JSON and contains a field 'transcription'
            if let transcriptionResult = try? JSONDecoder().decode(TranscriptionResponse.self, from: data) {
                return transcriptionResult.transcription
            } else {
                throw WhisperServiceError.invalidData
            }
            
        } catch {
            throw WhisperServiceError.requestFailed(error)
        }
    }
    
    // Helper function to create URLRequest
    private func createRequest(with audioURL: URL) -> URLRequest {
        var request = URLRequest(url: audioURL) // Replace with the actual Whisper API URL
        request.httpMethod = "POST"
        // Add headers as per Whisper API requirements, e.g.:
        // request.setValue("Bearer YOUR_API_KEY", forHTTPHeaderField: "Authorization")
        // request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // If the API expects a JSON with a file reference, set the proper body
        // If it expects a multipart/form-data upload, you'd construct that here
        
        return request
    }
}

// Define the response structure according to the Whisper API documentation
struct TranscriptionResponse: Decodable {
    let transcription: String
}
