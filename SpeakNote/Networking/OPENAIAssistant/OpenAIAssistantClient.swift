//
//  OpenAIAssistantClient.swift
//  SpeakNote
//
//  Created by Sailor on 12/9/23.
//

import Foundation

enum AssistantClientError: Error {
    case invalidURL
    case invalidAPIKey
    case invalidAssistantId
    case invalidThreadId
    case networkError(statusCode: Int, response: URLResponse, data: String?)
    case decodingError
}

class AssistantClient {
    var apiKey: String? = nil
    var assistantId: String? = nil
    var threadId: String? = nil
    
    var assistant: Assistant? = nil
    
    init() {
        apiKey = getAPIKey()
        assistantId = getAssistantID()
        Task {
            do {
                try threadId = await getThreadID()
            } catch {
                print(error)
            }
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
    
    private func getAssistantID() -> String? {
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
              let assistantID = dict["OPENAI AssistantID"] as? String else {
            return nil
        }
        return assistantID
    }
    
    private func getThreadID() async throws -> String {
        if let threadId = getThreadIDFromUserDefault(), !threadId.isEmpty {
            return threadId
        }
        
        let thread = try await createThread()
        saveThreadIDToUserDefault(threadId: thread.id)
        return thread.id
    }
    
    private func saveThreadIDToUserDefault(threadId: String) {
        UserDefaults.standard.setValue(threadId, forKey: "threadId")
    }
    
    private func getThreadIDFromUserDefault() -> String? {
        UserDefaults.standard.register(defaults: ["threadId": ""])
        let threadId = UserDefaults.standard.string(forKey: "threadId")
        return threadId
    }
}
