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
            fatalError("Invalid URL")
        }
        
        guard let apiKey = self.apiKey else {
            fatalError("Invalid apiKey")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("assistants=v1", forHTTPHeaderField: "OpenAI-Beta")
        
        var body: [String: Any] = [:]
        if let messages = messages {
            body["messages"] = messages
        }
        if let metadata = metadata {
            body["metadata"] = metadata
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonData
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let thread = try JSONDecoder().decode(Thread.self, from: data)
        return thread
    }
}
