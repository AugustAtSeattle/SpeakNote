//
//  OpenAIAssistantClient.swift
//  SpeakNote
//
//  Created by Sailor on 12/9/23.
//

import Foundation


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

struct Tool: Codable {
    let type: String
}




class AssistantClient {
    var apiKey: String? = nil
    var assistantId: String? = nil
    var threadId: String? = nil
    
    var assistant: Assistant? = nil
    
    init() {
        apiKey = getAPIKey()
        assistantId = getAssistantID()
        threadId = getThreadID()
        guard let assistantId = assistantId else {
            fatalError("Invalid assistantId")
        }
    }
    
    private func getAPIKey() -> String? {
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
              let apiKey = dict["OPENAI API Key"] as? String else {
            return nil
        }
        return apiKey
    }
    
    private func getThreadID() -> String? {
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
              let threadId = dict["OPENAI ThreadID"] as? String else {
            return nil
        }
        return threadID
    }
    
    private func getAssistantID() -> String? {
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
              let assistantID = dict["OPENAI AssistantID"] as? String else {
            return nil
        }
        return assistantID
    }
    
    
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
