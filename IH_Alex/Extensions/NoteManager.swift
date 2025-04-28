//
//  NoteManager.swift
//  IH_Alex
//
//  Created by Esther Elzek on 04/03/2025.
//

import Foundation


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
