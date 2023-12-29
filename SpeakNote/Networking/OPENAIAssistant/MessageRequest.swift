//
//  MessageRequest.swift
//  SpeakNote
//
//  Created by Sailor on 12/9/23.
//

import Foundation

struct Content: Codable {
    let type: String
    let text: Text?
}

struct Text: Codable {
    let value: String
    let annotations: [String]?
}

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

struct MessageList: Codable {
    let object: String
    let data: [Message]
    let firstId: String
    let lastId: String
    let hasMore: Bool
    
    enum CodingKeys: String, CodingKey {
        case object, data
        case firstId = "first_id"
        case lastId = "last_id"
        case hasMore = "has_more"
    }
}

struct AssistantResponse: Decodable {
    var query: String
    let description: String
}

extension AssistantClient {
    
    func createMessage(messageContent: String) async throws -> Message {
        guard let apiKey = apiKey else {
            throw AssistantClientError.invalidAPIKey
        }
        
        guard let threadId = threadId else {
            throw AssistantClientError.invalidThreadId
        }
        
        guard let url = URL(string: "https://api.openai.com/v1/threads/\(threadId)/messages") else {
            throw AssistantClientError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("assistants=v1", forHTTPHeaderField: "OpenAI-Beta")
        
        let body: [String: Any] = [
            "role": "user",
            "content": messageContent
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
            let message = try JSONDecoder().decode(Message.self, from: data)
            return message
        } catch{
            throw AssistantClientError.decodingError
        }
    }
    
    func attemptToReadLatestMessage(apiKey: String, url: URL) async throws -> Message? {
        var request = URLRequest(url: url)
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
            let messageList = try JSONDecoder().decode(MessageList.self, from: data)
            let messages = messageList.data
            let latestMessage = messages.last(where: { $0.role == "assistant" })
            if latestMessage == nil {
                throw AssistantClientError.noMessage
            }
            return latestMessage
        } catch let error as AssistantClientError where error == .noMessage {
            throw error
        } catch{
            throw AssistantClientError.decodingError
        }
    }
    
    func readLatestMessageFromThread() async throws -> Message? {
        guard let apiKey = apiKey else {
            throw AssistantClientError.invalidAPIKey
        }
        
        guard let threadId = threadId else {
            throw AssistantClientError.invalidThreadId
        }
        
        guard let url = URL(string: "https://api.openai.com/v1/threads/\(threadId)/messages?limit=1") else {
            throw AssistantClientError.invalidURL
        }
        
        let retryPolicy = RetryPolicy(maxAttempts: 3, delayInSeconds: 1)
        return try await retry(policy: retryPolicy) {
            try await self.attemptToReadLatestMessage(apiKey: apiKey, url: url)
        }
    }
    
    func extractAssistantResponse(from jsonString: String?) throws -> AssistantResponse {
        guard let jsonString = jsonString,
              let data = jsonString.data(using: .utf8) else {
            throw AssistantClientError.decodingError
        }
        do {
            var assistantResponse = try JSONDecoder().decode(AssistantResponse.self, from: data)
            assistantResponse.query = assistantResponse.query.replacingOccurrences(of: "\\n", with: " ", options: .literal, range: nil)
            return assistantResponse
        } catch let error as DecodingError {
            throw AssistantClientError.decodingError
        } catch {
            print(error)
            throw error
        }

    }
    
}



