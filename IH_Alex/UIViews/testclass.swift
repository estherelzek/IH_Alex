//
//  testclass.swift
//  IH_Alex
//
//  Created by Esther Elzek on 25/05/2025.
//

import Foundation
import UIKit

struct Chunk: Equatable, Codable {
    let attributedText: NSAttributedString
    let image: UIImage?
    let originalPageIndex: Int
    let pageNumberInChapter: Int
    let pageNumberInBook: Int
    let chapterNumber: Int
    let chunkNumber: Int
    let pageIndexInBook: Int
    let rangeInOriginal: NSRange
    let globalStartIndex: Int
    let globalEndIndex: Int
    
    static func == (lhs: Chunk, rhs: Chunk) -> Bool {
        return lhs.pageIndexInBook == rhs.pageIndexInBook &&
               lhs.chunkNumber == rhs.chunkNumber
    }

    enum CodingKeys: String, CodingKey {
        case attributedText
        case image
        case originalPageIndex
        case pageNumberInChapter
        case pageNumberInBook
        case chapterNumber
        case chunkNumber
        case pageIndexInBook
        case rangeInOriginal
        case globalStartIndex
        case globalEndIndex
    }

    // MARK: - Encodable
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        let attrData = try attributedText.data(
            from: NSRange(location: 0, length: attributedText.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd]
        )
        try container.encode(attrData, forKey: .attributedText)

        if let image = image,
           let imageData = image.pngData() {
            try container.encode(imageData, forKey: .image)
        }

        try container.encode(originalPageIndex, forKey: .originalPageIndex)
        try container.encode(pageNumberInChapter, forKey: .pageNumberInChapter)
        try container.encode(pageNumberInBook, forKey: .pageNumberInBook)
        try container.encode(chapterNumber, forKey: .chapterNumber)
        try container.encode(chunkNumber, forKey: .chunkNumber)
        try container.encode(pageIndexInBook, forKey: .pageIndexInBook)
        try container.encode([rangeInOriginal.location, rangeInOriginal.length], forKey: .rangeInOriginal)
        try container.encode(globalStartIndex, forKey: .globalStartIndex)
        try container.encode(globalEndIndex, forKey: .globalEndIndex)
    }

    // ✅ MARK: - Decodable
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let attrData = try container.decode(Data.self, forKey: .attributedText)
        attributedText = try NSAttributedString(
            data: attrData,
            options: [.documentType: NSAttributedString.DocumentType.rtfd],
            documentAttributes: nil
        )

        if let imageData = try? container.decode(Data.self, forKey: .image) {
            image = UIImage(data: imageData)
        } else {
            image = nil
        }

        originalPageIndex = try container.decode(Int.self, forKey: .originalPageIndex)
        pageNumberInChapter = try container.decode(Int.self, forKey: .pageNumberInChapter)
        pageNumberInBook = try container.decode(Int.self, forKey: .pageNumberInBook)
        chapterNumber = try container.decode(Int.self, forKey: .chapterNumber)
        chunkNumber = try container.decode(Int.self, forKey: .chunkNumber)
        pageIndexInBook = try container.decode(Int.self, forKey: .pageIndexInBook)

        let rangeArray = try container.decode([Int].self, forKey: .rangeInOriginal)
        rangeInOriginal = NSRange(location: rangeArray[0], length: rangeArray[1])

        globalStartIndex = try container.decode(Int.self, forKey: .globalStartIndex)
        globalEndIndex = try container.decode(Int.self, forKey: .globalEndIndex)
    }

    // Optional: custom initializer for manual creation
    init(
        attributedText: NSAttributedString,
        image: UIImage? = nil,
        originalPageIndex: Int,
        pageNumberInChapter: Int,
        pageNumberInBook: Int,
        chapterNumber: Int,
        chunkNumber: Int,
        pageIndexInBook: Int,
        rangeInOriginal: NSRange,
        globalStartIndex: Int,
        globalEndIndex: Int
    ) {
        self.attributedText = attributedText
        self.image = image
        self.originalPageIndex = originalPageIndex
        self.pageNumberInChapter = pageNumberInChapter
        self.pageNumberInBook = pageNumberInBook
        self.chapterNumber = chapterNumber
        self.chunkNumber = chunkNumber
        self.pageIndexInBook = pageIndexInBook
        self.rangeInOriginal = rangeInOriginal
        self.globalStartIndex = globalStartIndex
        self.globalEndIndex = globalEndIndex
    }
}

struct Page: Codable {
    let pageNumber: Int
    let pageNumberInChapter: Int
    let body: String
    let chapterNumber: Int
    let pageIndexInBook: Int
}

struct Chapterr: Codable {
    // From JSON
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

    // Not from JSON → must have defaults or be optional
    var numberOfPages: Int? = nil
    var pages: [Page] = []
    var chapterName: String? = nil

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
        // do NOT include numberOfPages, pages, chapterName
    }
}

extension Chapterr {
    func merge(with other: Chapterr) -> Chapterr {
        return Chapterr(
            id: self.id,
            bookID: self.bookID,
            count: self.count + other.count,
            content: self.content + other.content,
            size: self.size,
            firstPageNumber: min(self.firstPageNumber, other.firstPageNumber),
            lastPageNumber: max(self.lastPageNumber, other.lastPageNumber),
            firstChapterNumber: min(self.firstChapterNumber, other.firstChapterNumber),
            lastChapterNumber: max(self.lastChapterNumber, other.lastChapterNumber),
            lastUpdated: max(self.lastUpdated, other.lastUpdated),
            isDeleted: self.isDeleted ?? other.isDeleted,
            numberOfPages: self.numberOfPages ?? other.numberOfPages,
            pages: self.pages,           // Keep existing pages; or merge as needed
            chapterName: self.chapterName
        )
    }
}
