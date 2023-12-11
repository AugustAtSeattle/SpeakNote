//
//  ThreadRequest.swift
//  SpeakNote
//
//  Created by Sailor on 12/9/23.
//

import Foundation

struct Thread: Codable {
    let id: String
    let object: String
    let createdAt: Int
    let metadata: [String: String]?

    enum CodingKeys: String, CodingKey {
        case id, object, metadata
        case createdAt = "created_at"
    }
}

extension AssistantClient {
    func createThread(messages: [[String: String]]? = nil, metadata: [String: String]? = nil) async throws -> Thread {
        guard let url = URL(string: "https://api.openai.com/v1/threads") else {
            throw AssistantClientError.invalidURL
        }
        
        guard let apiKey = self.apiKey else {
            throw AssistantClientError.invalidAPIKey
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("assistants=v1", forHTTPHeaderField: "OpenAI-Beta")
                
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AssistantClientError.networkError(statusCode:(response as? HTTPURLResponse)?.statusCode ?? 0,
                                                    response: response,
                                                    data: String(data: data, encoding: .utf8))
        }
        
        do {
            let thread = try JSONDecoder().decode(Thread.self, from: data)
            return thread
        } catch {
            throw AssistantClientError.decodingError
        }
    }
}
