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
    let cover: String? // <-- Make `cover` optional
    let international_num: String?
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
        case international_num
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
        international_num: "",
        language: "Unknown",
        size: "",
        lastUpdated: 0,
        isDeleted: nil
    )
}
