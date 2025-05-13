//
//  BookContentModel.swift
//  IH_Alex
//
//  Created by esterelzek on 17/02/2025.
//

import Foundation

struct Chapter: Codable {
    let id: Int
    let bookID: Int
    let count: Int
    let content: String
    let size: String
    let firstPageNumber: Int
    let lastPageNumber: Int
    let firstChapterNumber: Int
    let lastChapterNumber: Int
    let lastUpdated: Int
    let isDeleted: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case bookID = "book_id"
        case count
        case content
        case size
        case firstPageNumber = "first_page_number"
        case lastPageNumber = "last_page_number"
        case firstChapterNumber = "first_chapter_number"
        case lastChapterNumber = "last_chapter_number"
        case lastUpdated = "last_updated"
        case isDeleted = "is_deleted"
    }
}

extension Chapter {
    func merge(with other: Chapter) -> Chapter {
        return Chapter(
            id: self.id, // Keep the same ID (or adjust if necessary)
            bookID: self.bookID, // Assuming bookID remains the same
            count: self.count + other.count, // Sum count
            content: self.content + other.content, // Concatenate content
            size: self.size, // Assuming size remains unchanged (adjust if needed)
            firstPageNumber: min(self.firstPageNumber, other.firstPageNumber), // Earliest page number
            lastPageNumber: max(self.lastPageNumber, other.lastPageNumber), // Latest page number
            firstChapterNumber: min(self.firstChapterNumber, other.firstChapterNumber), // Earliest chapter
            lastChapterNumber: max(self.lastChapterNumber, other.lastChapterNumber), // Latest chapter
            lastUpdated: max(self.lastUpdated, other.lastUpdated), // Take the latest update timestamp
            isDeleted: self.isDeleted ?? other.isDeleted // Preserve deletion status if applicable
        )
    }
}

struct Encoding: Codable {
    let tags: Tags
    let fonts: [String: FontStyle]
}

struct Tags: Codable {
    let tagStart, tagEnd: String
    let tagLength, formatLength, linkKeyLength: Int
    let webLink, internalLink, internalLinkTarget, image: String
    let reference, pageTag, chapterTag, splitTag: String
}

struct FontStyle: Codable {
    let bold, italic: String
    let size: String
    let fontColor, backgroundColor: String
    let align, underline, name: String?
    let fontFamilyName: String?
}



// TargetLink is empty in your example; define if needed

extension Chapter {
    static let `default` = Chapter(
        id: 0,
        bookID: 0,
        count: 0,
        content: "",
        size: "",
        firstPageNumber: 0,
        lastPageNumber: 0,
        firstChapterNumber: 0,
        lastChapterNumber: 0,
        lastUpdated: 0,
        isDeleted: nil
    )
}
