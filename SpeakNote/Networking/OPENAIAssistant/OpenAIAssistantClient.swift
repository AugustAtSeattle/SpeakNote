//
//  OpenAIAssistantClient.swift
//  SpeakNote
//
//  Created by Sailor on 12/9/23.
//

import Foundation

enum AssistantClientError: Error, Equatable {
    case invalidURL
    case invalidAPIKey
    case invalidAssistantId
    case invalidThreadId
    case networkError(statusCode: Int, response: URLResponse, data: String?)
    case decodingError
    case retryLimitReached
    case noMessage
    case openAIServiceError(message: String)
}

import Foundation

struct RetryPolicy {
    let maxAttempts: Int
    let delayInSeconds: UInt64

    init(maxAttempts: Int, delayInSeconds: UInt64) {
        self.maxAttempts = maxAttempts
        self.delayInSeconds = delayInSeconds
    }
}

enum RetryError: Error {
    case retryLimitReached(lastError: Error)
    case operationCancelled
}

func retry<T>(policy: RetryPolicy, task: @escaping () async throws -> T) async throws -> T {
    var attempts = 0

    while attempts < policy.maxAttempts {
        do {
            return try await task()
        } catch {
            attempts += 1

            if attempts >= policy.maxAttempts {
                throw RetryError.retryLimitReached(lastError: error)
            }

            if Task.isCancelled {
                throw RetryError.operationCancelled
            }

            try await Task.sleep(nanoseconds: policy.delayInSeconds * 1_000_000_000)
        }
    }
    
    throw RetryError.retryLimitReached(lastError: AssistantClientError.retryLimitReached)
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
