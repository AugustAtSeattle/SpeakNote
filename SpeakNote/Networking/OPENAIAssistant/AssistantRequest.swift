//
//  AssistantRequest.swift
//  SpeakNote
//
//  Created by Sailor on 12/9/23.
//

import Foundation
struct Tool: Codable {
    let type: String
}

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
    func getAssistant() async throws -> Assistant {
        guard let assistantId = self.assistantId else {
            throw AssistantClientError.invalidAssistantId
        }
        
        guard let apiKey = self.apiKey else {
            throw AssistantClientError.invalidAPIKey
        }
        
        guard let url = URL(string: "https://api.openai.com/v1/assistants/\(assistantId)") else {
            throw AssistantClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("assistants=v1", forHTTPHeaderField: "OpenAI-Beta")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        // print data in string
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AssistantClientError.networkError(statusCode:(response as? HTTPURLResponse)?.statusCode ?? 0,
                                                    response: response,
                                                    data: String(data: data, encoding: .utf8))
        }
        
        do {
            let assistant = try JSONDecoder().decode(Assistant.self, from: data)
            return assistant
        } catch {
            throw AssistantClientError.decodingError
        }
    }
}

