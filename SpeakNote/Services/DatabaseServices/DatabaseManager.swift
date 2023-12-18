//
//  DatabaseManager.swift
//  SpeakNote
//
//  Created by Sailor on 11/29/23.
//

import Foundation
import SQLite

enum QueryError: Error {
    case invalidQuery
}

class DatabaseManager {
    static let shared = DatabaseManager()
    public var connection: Connection?
    private let notesTable = Table("notes")
    private let id = Expression<Int64>("id")
    private let subject = Expression<String>("subject")
    private let details = Expression<String?>("details")
    private let createDate = Expression<String>("createDate")
    private let deadline = Expression<String?>("deadline")
    private let location = Expression<String?>("location")
    private let category = Expression<String>("category")
    private let status = Expression<String>("status")

    private init() {
        do {
            // Construct the file URL for the SQLite database in the documents directory
            let fileURL = try FileManager.default
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                .appendingPathComponent("db.sqlite3")

            // Create a connection to the database
            connection = try Connection(fileURL.path)
            try connection?.run(notesTable.drop(ifExists: true))

            // Create the notes table if it doesn't exist
            try connection?.run(notesTable.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(subject)
                t.column(details)
                t.column(createDate)
                t.column(deadline)
                t.column(location)
                t.column(category)
                t.column(status)
            })
        } catch {
            connection = nil
            print("Database initialization error: \(error)")
        }
    }

}

extension DatabaseManager {
    func executeQuery(_ query: String?) {
        guard let query = query else {
            print("error invalid query")
            return
        }
        
        guard let connection = connection else {
            print("empty connection")
            return
        }
        
        do {
            try connection.run(query)
            
            print("Query executed successfully.")
        } catch {
            print("An error occurred: \(error)")
        }
    }
    
    func createNote(subject: String, details: String?, dueDate: Date?, location: String?, category: String, status: NoteStatus) -> Bool {
        do {
            let insert = notesTable.insert(
                self.subject <- subject,
                self.details <- details,
                self.createDate <- createDate,
                self.deadline <- deadline,
                self.location <- location,
                self.category <- category,
                self.status <- status.rawValue
            )
            try connection?.run(insert)
            return true
        } catch {
            print("Insert failed: \(error)")
            return false
        }
    }

    
    func fetchNotes() -> [Note] {
        var notes = [Note]()

        do {
            for note in try connection!.prepare(notesTable) {
                notes.append(Note(id: note[id],
                                  subject: note[subject],
                                  details: note[details],
                                  createDate: note[createDate],
                                  deadline: note[deadline],
                                  location: note[location],
                                  category: note[category],
                                  status: NoteStatus(rawValue: note[status]) ?? .unknown))
            }
        } catch {
            print("Fetch failed: \(error)")
        }

        return notes
    }
    
    func markNoteAsFinished(noteId: Int64) -> Bool {
        let note = notesTable.filter(id == noteId)
        do {
            let update = note.update(status <- NoteStatus.finished.rawValue)
            if try connection?.run(update) ?? 0 > 0 {
                return true
            } else {
                print("No note was updated")
                return false
            }
        } catch {
            print("Update failed: \(error)")
            return false
        }
    }
}

extension DatabaseManager {
    func insertSampleNotesIfEmpty() {
        do {
            // Check if the notes table is empty
            let count = try connection?.scalar(notesTable.count) ?? 0
            if count == 0 {
                // Insert sample notes
                _ = createNote(subject: "Buy Eggs",
                               details: "Buy two dozen eggs from Costco",
                               dueDate: Date(timeIntervalSinceNow: 48 * 3600), // 2 days from now
                               location: "Costco",
                               category: "Shopping",
                               status: .pending)

                _ = createNote(subject: "Truck Height Info",
                               details: "Truck's height is 6 feet 4 without rack, 7.2 with rack",
                               dueDate: nil,
                               location: nil,
                               category: "Vehicle Info",
                               status: .unknown)

                _ = createNote(subject: "Buy Books",
                               details: "Buy two books named '5 mins story' from Amazon",
                               dueDate: nil,
                               location: "Amazon",
                               category: "Shopping",
                               status: .pending)

                // Add more sample notes as per the user cases
            }
        } catch {
            print("Error checking or populating the notes table: \(error)")
        }
    }
}

