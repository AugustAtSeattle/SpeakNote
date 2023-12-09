//
//  MessageRequest.swift
//  SpeakNote
//
//  Created by Sailor on 12/9/23.
//

import Foundation

struct Message: Codable {
    let id: String
    let object: String
    let createdAt: Int
    let threadId: String
    let role: String
    let content: [Content]
    let assistantId: String?
    let runId: String?
    let metadata: [String: String]?

    enum CodingKeys: String, CodingKey {
        case id, object, role, content, metadata
        case createdAt = "created_at"
        case threadId = "thread_id"
        case assistantId = "assistant_id"
        case runId = "run_id"
    }
}

struct Content: Codable {
    let type: String
    let text: Text?
}

struct Text: Codable {
    let value: String
    let annotations: [String]?
}

extension AssistantClient {
    
    func readLatestMessageFromThread(threadId: String) async throws -> Message? {
        guard let url = URL(string: "https://api.openai.com/v1/threads/\(threadId)/messages") else {
            fatalError("Invalid URL")
        }
        
        guard let apiKey = self.apiKey else {
            fatalError("Invalid apiKey")
        }
        
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let messages = try JSONDecoder().decode([Message].self, from: data)
        
        // Assuming the latest message is at the end of the array
        let latestMessage = messages.last(where: { $0.role == "assistant" })
        return latestMessage
    }
}
