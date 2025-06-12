//
//  Highlight.swift
//  IH_Alex
//
//  Created by Esther Elzek on 04/03/2025.
//

import Foundation



struct Highlight: Identifiable, Codable {
    let serverId: String?
    let id: Int64?
    let bookId: Int
    let chapterNumber: Int
    let pageNumberInChapter: Int
    let pageNumberInBook: Int
    let start: Int
    let end: Int
    let text: String
    let color: Int
    let lastUpdated: Date

    var identifier: String {
        return serverId ?? "\(id ?? -1)"
    }

    var isSynced: Bool {
        return serverId != nil
    }
}
