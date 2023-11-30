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

    private init() {
        do {
            // Construct the file URL for the SQLite database in the documents directory
            let fileURL = try FileManager.default
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                .appendingPathComponent("db.sqlite3")

            // Create a connection to the database
            db = try Connection(fileURL.path)

            // Create the notes table if it doesn't exist
            try db?.run(notesTable.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(title)
                t.column(body)
            })
        } catch {
            db = nil
            print("Database initialization error: \(error)")
        }
    }

}

extension DatabaseManager {
    func createNote(title: String, body: String) -> Bool {
        do {
            let insert = notesTable.insert(self.title <- title, self.body <- body)
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
                notes.append(Note(id: note[id], title: note[title], body: note[body]))
            }
        } catch {
            print("Fetch failed: \(error)")
        }
        
        return notes
    }
    
    func updateNoteById(id: Int64, newTitle: String, newBody: String) -> Bool {
        let note = notesTable.filter(self.id == id)
        do {
            let update = note.update([
                self.title <- newTitle,
                self.body <- newBody
            ])
            if try db!.run(update) > 0 {
                return true
            }
        } catch {
            print("Update failed: \(error)")
        }
        
        return false
    }
}
