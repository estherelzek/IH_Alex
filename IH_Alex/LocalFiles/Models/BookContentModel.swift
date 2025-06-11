//
//  BookContentModel.swift
//  IH_Alex
//
//  Created by esterelzek on 17/02/2025.
//

import Foundation

struct Chapter: Codable {
    // Properties loaded directly from JSON files
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
    
    // Properties NOT from JSON, added after processing
    var numberOfPages: Int?        // Computed after splitting content into pages
    var pages: [ChapterPages]?      // Split pages assigned after processing content
    var chapterName: String?       // Optional, can be assigned after loading or processing
    
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
        // Do NOT include keys for computed vars to avoid conflicts or override
    }
}


extension Chapter {
    func merge(with other: Chapter) -> Chapter {
        return Chapter(
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




// TargetLink is empty in your example; define if needed

//extension Chapter {
//    static let `default` = Chapter(
//        id: 0,
//        bookID: 0,
//        count: 0,
//        content: "",
//        size: "",
//        firstPageNumber: 0,
//        lastPageNumber: 0,
//        firstChapterNumber: 0,
//        lastChapterNumber: 0,
//        lastUpdated: 0,
//        isDeleted: nil,
//        numberOfPages: 0,
//        chapterName: ""
//        
//    )
//}
