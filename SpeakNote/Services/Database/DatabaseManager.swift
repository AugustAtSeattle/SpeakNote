//
//  DatabaseManager.swift
//  SpeakNote
//
//  Created by Sailor on 11/29/23.
//

import Foundation
import SQLite

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: Connection?
    private let notesTable = Table("notes")
    private let id = Expression<Int64>("id")
    private let title = Expression<String>("title")
    private let body = Expression<String>("body")
    private let details = Expression<String?>("details")
    private let dueDate = Expression<Date?>("dueDate")
    private let location = Expression<String?>("location")
    private let category = Expression<String?>("category")
    private let status = Expression<String>("status")

    private init() {
        do {
            // Construct the file URL for the SQLite database in the documents directory
            let fileURL = try FileManager.default
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                .appendingPathComponent("db.sqlite3")

            // Create a connection to the database
            db = try Connection(fileURL.path)
            
//            try db?.run(notesTable.drop(ifExists: true))

            // Create the notes table if it doesn't exist
            try db?.run(notesTable.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(title)
                t.column(details)
                t.column(dueDate)
                t.column(location)
                t.column(category)
                t.column(status)
            })
        } catch {
            db = nil
            print("Database initialization error: \(error)")
        }
    }

}

extension DatabaseManager {
    func createNote(title: String, details: String?, dueDate: Date?, location: String?, category: String?, status: NoteStatus) -> Bool {
        do {
            let insert = notesTable.insert(
                self.title <- title,
                self.details <- details,
                self.dueDate <- dueDate,
                self.location <- location,
                self.category <- category,
                self.status <- status.rawValue
            )
            try db?.run(insert)
            return true
        } catch {
            print("Insert failed: \(error)")
            return false
        }
    }

    
    func fetchNotes() -> [Note] {
        var notes = [Note]()

        do {
            for note in try db!.prepare(notesTable) {
                notes.append(Note(
                    id: note[id],
                    title: note[title],
                    details: note[details],
                    dueDate: note[dueDate],
                    location: note[location],
                    category: note[category],
                    status: NoteStatus(rawValue: note[status]) ?? .unknown
                ))
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
            if try db?.run(update) ?? 0 > 0 {
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
            let count = try db?.scalar(notesTable.count) ?? 0
            if count == 0 {
                // Insert sample notes
                _ = createNote(title: "Buy Eggs",
                               details: "Buy two dozen eggs from Costco",
                               dueDate: Date(timeIntervalSinceNow: 48 * 3600), // 2 days from now
                               location: "Costco",
                               category: "Shopping",
                               status: .pending)

                _ = createNote(title: "Truck Height Info",
                               details: "Truck's height is 6 feet 4 without rack, 7.2 with rack",
                               dueDate: nil,
                               location: nil,
                               category: "Vehicle Info",
                               status: .unknown)

                _ = createNote(title: "Buy Books",
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
