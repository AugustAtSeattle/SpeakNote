//
//  RunRequest.swift
//  SpeakNote
//
//  Created by Sailor on 12/9/23.
//

import Foundation

struct Run: Codable {
    let id: String
    let object: String
    let createdAt: Int
    let threadId: String
    let assistantId: String
    let status: String
    let model: String
    let tools: [String]
    let metadata: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id, object, status, model, tools, metadata
        case createdAt = "created_at"
        case threadId = "thread_id"
        case assistantId = "assistant_id"
    }
}

extension AssistantClient {
    func createRun(threadId: String, assistantId: String, model: String? = nil, instructions: String? = nil, tools: [String]? = nil, metadata: [String: String]? = nil) async throws -> Run {
        guard let url = URL(string: "https://api.openai.com/v1/threads/\(threadId)/runs") else {
            fatalError("Invalid URL")
        }
        
        guard let apiKey = self.apiKey else {
            fatalError("Invalid apiKey")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        var body: [String: Any] = [
            "assistant_id": assistantId
        ]
        if let model = model {
            body["model"] = model
        }
        if let instructions = instructions {
            body["instructions"] = instructions
        }
        if let tools = tools {
            body["tools"] = tools
        }
        if let metadata = metadata {
            body["metadata"] = metadata
        }

        let jsonData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonData

        let (data, _) = try await URLSession.shared.data(for: request)
        let run = try JSONDecoder().decode(Run.self, from: data)
        return run
    }
}
