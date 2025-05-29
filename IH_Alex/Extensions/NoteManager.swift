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

    // MARK: - Save a Single Note
    func saveNote(_ note: Note) {
        var notes = loadNotes()
        notes.append(note)
        saveAllNotes(notes)
    }

    // MARK: - Save All Notes
    func saveAllNotes(_ notes: [Note]) {
        let noteDicts = notes.map { $0.toDictionary() }
        UserDefaults.standard.set(noteDicts, forKey: notesKey)
    }

    // MARK: - Load All Notes
    func loadNotes() -> [Note] {
        guard let savedNotes = UserDefaults.standard.array(forKey: notesKey) as? [[String: Any]] else {
            return []
        }
        return savedNotes.compactMap { Note.fromDictionary($0) }
    }

    // MARK: - Load Notes for Chapter Pages (adjusted ranges)
    func loadNotes(for pages: [ChapterPages]) -> [Note] {
        let savedNotes = loadNotes()
        var adjustedNotes: [Note] = []

        for note in savedNotes {
            if let newRange = findAdjustedRange(start: note.start, end: note.end, in: pages) {
                let updatedNote = note.withUpdatedRange(start: newRange.location, end: newRange.location + newRange.length)
                adjustedNotes.append(updatedNote)
            }
        }

        return adjustedNotes
    }

    // MARK: - Find Relative Range for Global Start/End
    private func findAdjustedRange(start: Int, end: Int, in pages: [ChapterPages]) -> NSRange? {
        for page in pages {
            if NSLocationInRange(start, page.rangeInOriginal) {
                let relativeLocation = start - page.rangeInOriginal.location
                let relativeLength = end - start
                return NSRange(location: relativeLocation, length: relativeLength)
            }
        }
        return nil
    }
}
