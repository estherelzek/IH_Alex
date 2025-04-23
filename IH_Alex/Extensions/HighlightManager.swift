//
//  HighlightManager.swift
//  IH_Alex
//
//  Created by Esther Elzek on 04/03/2025.
//

import Foundation
import UIKit

struct Highlight: Codable {
    var range: NSRange
    var page: Int
    var globalRange: NSRange // The original range before pagination
    var color: String // Color stored as a hex string

    // Initializer to create a highlight with a range, page, global range, and color
    init(range: NSRange, page: Int, globalRange: NSRange, color: String) {
        self.range = range
        self.page = page
        self.globalRange = globalRange
        self.color = color
    }

    // Method to update the range of an existing highlight
    func withUpdatedRange(_ newRange: NSRange) -> Highlight {
        var updatedHighlight = self
        updatedHighlight.range = newRange
        return updatedHighlight
    }
}

class HighlightManager {
    static let shared = HighlightManager()
    private let highlightsKey = "bookHighlights"

    // Save a single highlight
    func saveHighlight(_ highlight: Highlight) {
        var highlights = loadHighlights()
        highlights.append(highlight)
        if let data = try? JSONEncoder().encode(highlights) {
            UserDefaults.standard.set(data, forKey: highlightsKey)
        }
    }

    // Load all saved highlights
    func loadHighlights() -> [Highlight] {
        guard let data = UserDefaults.standard.data(forKey: highlightsKey),
              let highlights = try? JSONDecoder().decode([Highlight].self, from: data) else {
            return []
        }
        return highlights
    }

    // Remove a specific highlight
    func removeHighlight(_ highlight: Highlight) {
        var highlights = loadHighlights()
        highlights.removeAll { $0.range == highlight.range && $0.page == highlight.page }
        if let data = try? JSONEncoder().encode(highlights) {
            UserDefaults.standard.set(data, forKey: highlightsKey)
        }
    }

    // Save all highlights at once
    func saveAllHighlights(_ highlights: [Highlight]) {
        if let data = try? JSONEncoder().encode(highlights) {
            UserDefaults.standard.set(data, forKey: highlightsKey)
        }
    }

    // Adjust highlights for the current pagination
    func loadHighlights(for pages: [PageContent]) -> [Highlight] {
        guard let data = UserDefaults.standard.data(forKey: highlightsKey),
              let savedHighlights = try? JSONDecoder().decode([Highlight].self, from: data) else {
            return []
        }

        var adjustedHighlights: [Highlight] = []

        for highlight in savedHighlights {
            if let newRange = findRange(for: highlight.globalRange, in: pages) {
                adjustedHighlights.append(highlight.withUpdatedRange(newRange))
            }
        }
        return adjustedHighlights
    }

    // Find the new range of a highlight based on the global range and current page content
    func findRange(for globalRange: NSRange, in pages: [PageContent]) -> NSRange? {
        for page in pages {
            // Check if the highlight range falls within this page's original range
            if NSLocationInRange(globalRange.location, page.rangeInOriginal) {
                let relativeLocation = globalRange.location - page.rangeInOriginal.location
                let newRange = NSRange(location: relativeLocation, length: globalRange.length)
                return newRange
            }
        }
        return nil
    }
}


//
//class HighlightManager {
//    static let shared = HighlightManager()
//    private init() {}
//
//    private let highlightsKey = "savedHighlights"
//
//    func saveHighlight(_ highlight: Highlight) {
//        var highlights = loadHighlights()
//        highlights.removeAll { $0.page == highlight.page && $0.range.location == highlight.range.location }
//        highlights.append(highlight)
//        saveAllHighlights(highlights)
//    }
//
//    func loadHighlights() -> [Highlight] {
//        guard let data = UserDefaults.standard.data(forKey: highlightsKey),
//              let highlights = try? JSONDecoder().decode([Highlight].self, from: data) else {
//            return []
//        }
//        return highlights
//    }
//
//    func saveAllHighlights(_ highlights: [Highlight]) {
//        if let data = try? JSONEncoder().encode(highlights) {
//            UserDefaults.standard.set(data, forKey: highlightsKey)
//        }
//    }
//
//    func highlightsForPage(_ page: Int) -> [Highlight] {
//        return loadHighlights().filter { $0.page == page }
//    }
//
//    func removeHighlights(in range: NSRange, on page: Int) {
//        var highlights = loadHighlights()
//        highlights.removeAll { NSIntersectionRange($0.range, range).length > 0 && $0.page == page }
//        saveAllHighlights(highlights)
//    }
//}
//
