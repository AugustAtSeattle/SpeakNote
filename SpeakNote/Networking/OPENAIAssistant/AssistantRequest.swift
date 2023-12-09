//
//  AssistantRequest.swift
//  SpeakNote
//
//  Created by Sailor on 12/9/23.
//

import Foundation

struct Assistant: Codable {
    let id: String
    let object: String
    let createdAt: Int
    let name: String?
    let description: String?
    let model: String
    let instructions: String?
    let tools: [Tool]
    let fileIds: [String]
    let metadata: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id, object, model, tools, metadata
        case createdAt = "created_at"
        case name, description, instructions
        case fileIds = "file_ids"
    }
}

extension AssistantClient {
    func getAssistant(assistantId: String) async throws -> Assistant {
        guard let url = URL(string: "https://api.openai.com/v1/assistants/\(assistantId)") else {
            fatalError("Invalid URL")
        }
        
        guard let assistantId = self.assistantId else {
            fatalError("Invalid assistantId")
        }

        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(assistantId)", forHTTPHeaderField: "Authorization")
        request.addValue("assistants=v1", forHTTPHeaderField: "OpenAI-Beta")

        let (data, _) = try await URLSession.shared.data(for: request)
        let assistant = try JSONDecoder().decode(Assistant.self, from: data)
        return assistant
    }
}
