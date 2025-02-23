//
//  BookModel.swift
//  IH_Alex
//
//  Created by esterelzek on 17/02/2025.
//

import Foundation

struct BookResponse: Codable {
    let book: Book
    let categories: [Category]
    let tags: [Tag]
    let author: [Author]
    let publisher: [Publisher]
    let translators: [Translator]
}

struct Book: Codable {
    let id: Int
    let name: String
    let description: String
    let summary: String
    let pagesNumber: Int
    let chaptersNumber: Int
    let readingProgress: Int?
    let subscriptionID: Int
    let releaseDate: String
    let bookRating: Int?
    let publisherID: Int
    let cover: String
    let internationalNum: String
    let language: String
    let size: String
    let lastUpdated: Int
    let isDeleted: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, description, summary
        case pagesNumber = "pages_number"
        case chaptersNumber = "chapters_number"
        case readingProgress = "reading_progress"
        case subscriptionID = "subscription_id"
        case releaseDate = "release_date"
        case bookRating = "book_rating"
        case publisherID = "publisher_id"
        case cover
        case internationalNum = "international_num"
        case language, size
        case lastUpdated = "last_updated"
        case isDeleted = "is_deleted"
    }
}

struct Category: Codable {
    let id: Int
    let name: String
    let lastUpdated: Int
    let isDeleted: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name
        case lastUpdated = "last_updated"
        case isDeleted = "is_deleted"
    }
}

struct Tag: Codable {
    let id: Int
    let name: String
    let lastUpdated: Int
    let isDeleted: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name
        case lastUpdated = "last_updated"
        case isDeleted = "is_deleted"
    }
}

struct Author: Codable {
    let id: Int
    let name: String
    let lastUpdated: Int
    let isDeleted: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name
        case lastUpdated = "last_updated"
        case isDeleted = "is_deleted"
    }
}

struct Publisher: Codable {
    let id: Int
    let name: String
    let lastUpdated: Int
    let isDeleted: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name
        case lastUpdated = "last_updated"
        case isDeleted = "is_deleted"
    }
}

struct Translator: Codable {
    let id: Int
    let name: String
    let lastUpdated: Int
    let isDeleted: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name
        case lastUpdated = "last_updated"
        case isDeleted = "is_deleted"
    }
}
struct BookContent: Codable {
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
struct MetaDataResponse: Codable {
    let bookID: Int
    let encoding: String  // JSON string that needs manual decoding
    let index: String     // JSON string that needs manual decoding
    let targetLinks: String

    enum CodingKeys: String, CodingKey {
        case bookID = "book_id"
        case encoding
        case index
        case targetLinks = "target_links"
    }

    // Decode encoding JSON string into Encoding struct
    func decodedEncoding() -> Encoding? {
        guard let data = encoding.data(using: .utf8) else { return nil }
        do {
            return try JSONDecoder().decode(Encoding.self, from: data)
        } catch {
            print("❌ Error decoding encoding: \(error)")
            return nil
        }
    }

    // Decode index JSON string into an array of BookIndex
    func decodedIndex() -> [BookIndex]? {
        guard let data = index.data(using: .utf8) else { return nil }
        do {
            return try JSONDecoder().decode([BookIndex].self, from: data)
        } catch {
            print("❌ Error decoding index: \(error)")
            return nil
        }
    }
}

// Encoding structure
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

// Book Index structure
struct BookIndex: Codable {
    let name: String
    let number, pageNumber: Int
}

// TargetLink is empty in your example; define if needed
struct TargetLink: Codable {}
extension BookContent {
    static let `default` = BookContent(
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
extension Book {
    static let `default` = Book(
        id: 0,
        name: "Unknown",
        description: "",
        summary: "",
        pagesNumber: 0,
        chaptersNumber: 0,
        readingProgress: nil,
        subscriptionID: 0,
        releaseDate: "",
        bookRating: nil,
        publisherID: 0,
        cover: "",
        internationalNum: "",
        language: "Unknown",
        size: "",
        lastUpdated: 0,
        isDeleted: nil
    )
}
extension MetaDataResponse {
    static let `default` = MetaDataResponse(
        bookID: 0,
        encoding: "",
        index: "",
        targetLinks: ""
    )
}
