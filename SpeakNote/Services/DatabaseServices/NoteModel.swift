//
//  NoteModel.swift
//  SpeakNote
//
//  Created by Sailor on 11/29/23.
//

import Foundation

enum NoteStatus: String {
    case finished = "Completed"
    case pending = "Pending"
    case unknown = "Unknown"
    case recurring = "Recurring"
}

struct Note {
    let id: Int64
    let subject: String
    let details: String?
    let createDate: String
    let deadline: String?
    let location: String?
    let category: String?
    let status: NoteStatus
}

