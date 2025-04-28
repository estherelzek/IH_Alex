//
//  Highlight.swift
//  IH_Alex
//
//  Created by Esther Elzek on 04/03/2025.
//

import Foundation

struct Highlight: Codable {
    var range: NSRange
    var page: Int
    var globalRange: NSRange // The original range before pagination
    var color: String // Color stored as a hex string

    init(range: NSRange, page: Int, globalRange: NSRange, color: String) {
        self.range = range
        self.page = page
        self.globalRange = globalRange
        self.color = color
    }

    func withUpdatedRange(_ newRange: NSRange) -> Highlight {
        var updatedHighlight = self
        updatedHighlight.range = newRange
        return updatedHighlight
    }
}
