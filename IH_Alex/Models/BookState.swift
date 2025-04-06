//
//  BookState.swift
//  IH_Alex
//
//  Created by Esther Elzek on 04/03/2025.
//

import Foundation

struct BookState {
    let bookId: Int
    let bookName: String
    let pagesNumber: Int
    let chaptersNumber: Int
    let description: String
    let cover: String?
    let bookSize: Float?
    let readingProgress: Int?
    var chapters: [Chapter]
    let bookMetadata: BookMetadata?
    let subscriptionId: Int
    let summary: String?
    let bookRating: Double?
    let releaseDate: String?
    let publisherName: String?
    let internationalNum: String?
    let language: String
    let categories: [Category]
    let authorsName: [String]
    let tags: [Tag]
    let translatorsName: [String]
    let bookHighlights: [Highlight]
    let bookBookmarks: [Bookmark]
    let bookNotes: [Note]

    init(
        bookId: Int = -1,
        bookName: String = "",
        pagesNumber: Int = 0,
        chaptersNumber: Int = 0,
        description: String = "",
        cover: String? = "",
        bookSize: Float? = nil,
        readingProgress: Int? = nil,
        chapters: [Chapter] = [],
        bookMetadata: BookMetadata? = nil,
        subscriptionId: Int = -1,
        summary: String? = nil,
        bookRating: Double? = nil,
        releaseDate: String? = nil,
        publisherName: String? = nil,
        internationalNum: String? = nil,
        language: String = "",
        categories: [Category] = [],
        authorsName: [String] = [],
        tags: [Tag] = [],
        translatorsName: [String] = [],
        bookHighlights: [Highlight] = [],
        bookBookmarks: [Bookmark] = [],
        bookNotes: [Note] = []
    ) {
        self.bookId = bookId
        self.bookName = bookName
        self.pagesNumber = pagesNumber
        self.chaptersNumber = chaptersNumber
        self.description = description
        self.cover = cover
        self.bookSize = bookSize
        self.readingProgress = readingProgress
        self.chapters = chapters
        self.bookMetadata = bookMetadata
        self.subscriptionId = subscriptionId
        self.summary = summary
        self.bookRating = bookRating
        self.releaseDate = releaseDate
        self.publisherName = publisherName
        self.internationalNum = internationalNum
        self.language = language
        self.categories = categories
        self.authorsName = authorsName
        self.tags = tags
        self.translatorsName = translatorsName
        self.bookHighlights = bookHighlights
        self.bookBookmarks = bookBookmarks
        self.bookNotes = bookNotes
    }
}

struct Note: Codable {
    var page: Int
    var range: NSRange
    var title: String  // New property for title
    var content: String
    var position: CGPoint?

    func toDictionary() -> [String: Any] {
        return [
            "page": page,
            "range": ["location": range.location, "length": range.length],
            "title": title,  // Include title in dictionary
            "content": content,
            "position": position != nil ? ["x": position!.x, "y": position!.y] : nil
        ].compactMapValues { $0 }
    }

    static func fromDictionary(_ dict: [String: Any]) -> Note? {
        guard let page = dict["page"] as? Int,
              let rangeDict = dict["range"] as? [String: Int],
              let location = rangeDict["location"],
              let length = rangeDict["length"],
              let title = dict["title"] as? String,  // Retrieve title
              let content = dict["content"] as? String else { return nil }

        let range = NSRange(location: location, length: length)

        var position: CGPoint? = nil
        if let positionDict = dict["position"] as? [String: CGFloat],
           let x = positionDict["x"],
           let y = positionDict["y"] {
            position = CGPoint(x: x, y: y)
        }

        return Note(page: page, range: range, title: title, content: content, position: position)
    }
}



struct Chapter: Codable {
    let chapterNumber: Int
    let title: String
    let content: String
}

struct BookMetadata: Codable {
    let lastUpdated: Int
    let isDeleted: Bool?
}
class NoteSpan {
    let id: UUID
    var bounds: CGRect
    
    init(bounds: CGRect) {
        self.id = UUID()
        self.bounds = bounds
    }

    func isIconClicked() {
        print("Note icon tapped for NoteSpan: \(id)")
        // Handle note selection, display popup, etc.
    }
}
