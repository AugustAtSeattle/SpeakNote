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
    func createRun() async throws -> Run {
        guard let apiKey = apiKey else {
            throw AssistantClientError.invalidAPIKey
        }
        
        guard let assistantId = assistantId else {
            throw AssistantClientError.invalidAssistantId
        }
        
        guard let threadId = threadId else {
            throw AssistantClientError.invalidThreadId
        }
        
        guard let url = URL(string: "https://api.openai.com/v1/threads/\(threadId)/runs") else {
            throw AssistantClientError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("assistants=v1", forHTTPHeaderField: "OpenAI-Beta")

        var body: [String: Any] = [
            "assistant_id": assistantId
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AssistantClientError.networkError(statusCode:(response as? HTTPURLResponse)?.statusCode ?? 0,
                                                    response: response,
                                                    data: String(data: data, encoding: .utf8))
        }
        
        do {
            let run = try JSONDecoder().decode(Run.self, from: data)
            return run
        } catch {
            throw AssistantClientError.decodingError
        }
    }
    
    func checkRunStatus(runId: String) async throws -> String {
        
        guard let apiKey = apiKey else {
            throw AssistantClientError.invalidAPIKey
        }
        
        guard let assistantId = assistantId else {
            throw AssistantClientError.invalidAssistantId
        }
        
        guard let threadId = threadId else {
            throw AssistantClientError.invalidThreadId
        }
    
        guard let url = URL(string: "https://api.openai.com/v1/threads/\(threadId)/runs/\(runId)") else {
            throw AssistantClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("assistants=v1", forHTTPHeaderField: "OpenAI-Beta")

        let (data, _) = try await URLSession.shared.data(for: request)
        let run = try JSONDecoder().decode(Run.self, from: data)

        return run.status
    }
}
