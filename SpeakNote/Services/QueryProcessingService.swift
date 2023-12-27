//
//  QueryProcessingService.swift
//  SpeakNote
//
//  Created by Sailor on 12/26/23.
//

import Foundation


class QueryProcessingService {
    private let assistant = AssistantClient()
    private let databaseManager = DatabaseManager.shared
    
    
    func processQuery(_ userQuery: String) async throws -> String {
        //TODO: validated messageContent
        let messageContent = userQuery
        _ = try await assistant.createMessage(messageContent: messageContent)
        let run = try await assistant.createRun()
        let runStatus = try await checkRunStatus(run: run)
        let latestMessage = try await assistant.readLatestMessageFromThread()
        return try await processLatestMessage(latestMessage: latestMessage)
    }
        
    
    func checkRunStatus(run: Run) async throws -> RunStatus {
        var runStatus: RunStatus?
        repeat {
            runStatus = try await assistant.getRunStatus(runId: run.id)
            guard runStatus == .queued ||
                    runStatus == .inProgress ||
                    runStatus == .completed else {
                throw AssistantClientError.openAIServiceError(message: runStatus?.rawValue ?? "Unknown error")
            }
            
            if let status = runStatus, status != .completed {
                try await Task.sleep(nanoseconds: 1_000_000_000) // sleep for 1 second before next status check
            }
        } while runStatus != .completed
        return runStatus!
    }
    
    func processLatestMessage(latestMessage: Message?)  async throws -> String {
        guard let latestMessage = latestMessage else {
            print("No SQL query found in the message")
            throw QueryError.dataNotFound
        }
        
        if let response = assistant.extractAssistantResponse(from: latestMessage.content.first?.text?.value) {
            let query = response.query
            let queryResult = try databaseManager.executeQuery(query)
            let description = queryResult.QueryType != .select ? response.description : (queryResult.Result ?? "No results found")
            return description
        } else {
            throw QueryError.dataNotFound
        }
    }
}
