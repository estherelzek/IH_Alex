//
//  NoteModel.swift
//  IH_Alex
//
//  Created by Esther Elzek on 27/04/2025.
//

import Foundation

struct Note: Codable {
    var id: Int64
    var bookId: Int
    var chapterNumber: Int
    var pageNumberInChapter: Int
    var pageNumberInBook: Int
    var start: Int
    var end: Int
    var noteText: String
    var selectedNoteText: String
    var lastUpdated: Date

    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "bookId": bookId,
            "chapterNumber": chapterNumber,
            "pageNumberInChapter": pageNumberInChapter,
            "pageNumberInBook": pageNumberInBook,
            "start": start,
            "end": end,
            "noteText": noteText,
            "selectedNoteText": selectedNoteText,
            "lastUpdated": ISO8601DateFormatter().string(from: lastUpdated)
        ]
    }

    static func fromDictionary(_ dict: [String: Any]) -> Note? {
        guard let id = dict["id"] as? Int64 ?? (dict["id"] as? Int).map(Int64.init),
              let bookId = dict["bookId"] as? Int,
              let chapterNumber = dict["chapterNumber"] as? Int,
              let pageNumberInChapter = dict["pageNumberInChapter"] as? Int,
              let pageNumberInBook = dict["pageNumberInBook"] as? Int,
              let start = dict["start"] as? Int,
              let end = dict["end"] as? Int,
              let noteText = dict["noteText"] as? String,
              let selectedNoteText = dict["selectedNoteText"] as? String,
              let lastUpdatedString = dict["lastUpdated"] as? String,
              let lastUpdated = ISO8601DateFormatter().date(from: lastUpdatedString)
        else {
            return nil
        }

        return Note(
            id: id,
            bookId: bookId,
            chapterNumber: chapterNumber,
            pageNumberInChapter: pageNumberInChapter,
            pageNumberInBook: pageNumberInBook,
            start: start,
            end: end,
            noteText: noteText,
            selectedNoteText: selectedNoteText,
            lastUpdated: lastUpdated
        )
    }

    func withUpdatedRange(start: Int, end: Int) -> Note {
        var updated = self
        updated.start = start
        updated.end = end
        return updated
    }
}
