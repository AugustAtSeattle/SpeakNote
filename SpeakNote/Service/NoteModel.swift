//
//  NoteModel.swift
//  SpeakNote
//
//  Created by Sailor on 11/29/23.
//

import Foundation

enum NoteStatus: String {
    case finished = "Finished"
    case pending = "Pending"  // Replacing "Not Yet" with "Pending"
    case unknown = "Unknown"
}


struct Note {
    let id: Int64
    let title: String
    let details: String?
    let dueDate: Date?
    let location: String?
    let category: String?
    let status: NoteStatus
}

