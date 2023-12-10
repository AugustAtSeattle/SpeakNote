//
//  OpenAIAssistantClient.swift
//  SpeakNote
//
//  Created by Sailor on 12/9/23.
//

import Foundation

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
              let threadID = dict["OPENAI ThreadID"] as? String else {
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
}
