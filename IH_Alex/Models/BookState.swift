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
    var chapters: [ChapterData]
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
        chapters: [ChapterData] = [],
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

struct ChapterData: Codable {
    let chapterNumber: Int
    let title: String
    let content: String
}

struct BookMetadata: Codable {
    let lastUpdated: Int
    let isDeleted: Bool?
}

