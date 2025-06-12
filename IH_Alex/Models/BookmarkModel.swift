//
//  BookmarkModel.swift
//  IH_Alex
//
//  Created by Esther Elzek on 27/04/2025.
//

import Foundation

struct Bookmark: Codable {
    let serverId: String?
    let id: Int64
    let bookId: Int
    let chapterNumber: Int
    let pageNumberInChapter: Int
    let pageNumberInBook: Int
    let text: String
    let lastUpdated: Date

    init(
        serverId: String? = nil,
        id: Int64,
        bookId: Int,
        chapterNumber: Int,
        pageNumberInChapter: Int,
        pageNumberInBook: Int,
        text: String = "",
        lastUpdated: Date
    ) {
        self.serverId = serverId
        self.id = id
        self.bookId = bookId
        self.chapterNumber = chapterNumber
        self.pageNumberInChapter = pageNumberInChapter
        self.pageNumberInBook = pageNumberInBook
        self.text = text
        self.lastUpdated = lastUpdated
    }
}
