//
//  NoteManager.swift
//  IH_Alex
//
//  Created by Esther Elzek on 04/03/2025.
//

import Foundation
struct Note: Codable {
    var page: Int
    var range: NSRange
    var globalRange: NSRange // New
    var title: String
    var content: String
    var position: CGPoint?

    func toDictionary() -> [String: Any] {
        return [
            "page": page,
            "range": ["location": range.location, "length": range.length],
            "globalRange": ["location": globalRange.location, "length": globalRange.length],
            "title": title,
            "content": content,
            "position": position != nil ? ["x": position!.x, "y": position!.y] : nil
        ].compactMapValues { $0 }
    }

    static func fromDictionary(_ dict: [String: Any]) -> Note? {
        guard let page = dict["page"] as? Int,
              let rangeDict = dict["range"] as? [String: Int],
              let globalRangeDict = dict["globalRange"] as? [String: Int],
              let location = rangeDict["location"],
              let length = rangeDict["length"],
              let globalLocation = globalRangeDict["location"],
              let globalLength = globalRangeDict["length"],
              let title = dict["title"] as? String,
              let content = dict["content"] as? String else { return nil }

        let range = NSRange(location: location, length: length)
        let globalRange = NSRange(location: globalLocation, length: globalLength)

        var position: CGPoint? = nil
        if let positionDict = dict["position"] as? [String: CGFloat],
           let x = positionDict["x"],
           let y = positionDict["y"] {
            position = CGPoint(x: x, y: y)
        }

        return Note(page: page, range: range, globalRange: globalRange, title: title, content: content, position: position)
    }

    func withUpdatedRange(_ newRange: NSRange) -> Note {
        var updated = self
        updated.range = newRange
        return updated
    }
}


class NoteManager {
    static let shared = NoteManager()
    private let notesKey = "savedNotes"

    func saveNote(_ note: Note) {
        var notes = loadNotes()
        notes.append(note)
        saveAllNotes(notes)
    }

    func saveAllNotes(_ notes: [Note]) {
        let noteDicts = notes.map { $0.toDictionary() }
        UserDefaults.standard.set(noteDicts, forKey: notesKey)
    }

    func loadNotes() -> [Note] {
        guard let savedNotes = UserDefaults.standard.array(forKey: notesKey) as? [[String: Any]] else {
            return []
        }
        return savedNotes.compactMap { Note.fromDictionary($0) }
    }

    /// Adjusts all notes to the current pagination
    func loadNotes(for pages: [PageContent]) -> [Note] {
        let savedNotes = loadNotes()
        var adjustedNotes: [Note] = []

        for note in savedNotes {
            if let newRange = findRange(for: note.globalRange, in: pages) {
                adjustedNotes.append(note.withUpdatedRange(newRange))
            }
        }

        return adjustedNotes
    }

    private func findRange(for globalRange: NSRange, in pages: [PageContent]) -> NSRange? {
        for page in pages {
            if NSLocationInRange(globalRange.location, page.rangeInOriginal) {
                let relativeLocation = globalRange.location - page.rangeInOriginal.location
                return NSRange(location: relativeLocation, length: globalRange.length)
            }
        }
        return nil
    }
}
