//
//  QueryProcessingService.swift
//  SpeakNote
//
//  Created by Sailor on 12/26/23.
//

import Foundation

class QueryProcessingService {
    private let assistantClient: AssistantClient
    private let databaseManager: DatabaseManager

    init(assistantClient: AssistantClient, databaseManager: DatabaseManager) {
        self.assistantClient = assistantClient
        self.databaseManager = databaseManager
    }

    func processQuery(_ query: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Implement the sequence of operations currently in performQueryHelper
        // Instead of directly updating the UI, use the completion handler to return the result
    }
}
