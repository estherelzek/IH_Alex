//
//  HighlightManager.swift
//  IH_Alex
//
//  Created by Esther Elzek on 04/03/2025.
//

import Foundation
import UIKit

class HighlightManager {
    static let shared = HighlightManager()
    private let highlightsKey = "bookHighlights"

    func saveHighlight(_ highlight: Highlight) {
        var highlights = loadHighlights()
        highlights.append(highlight)
        if let data = try? JSONEncoder().encode(highlights) {
            UserDefaults.standard.set(data, forKey: highlightsKey)
        }
    }

    func loadHighlights() -> [Highlight] {
        guard let data = UserDefaults.standard.data(forKey: highlightsKey),
              let highlights = try? JSONDecoder().decode([Highlight].self, from: data) else {
            return []
        }
        return highlights
    }

    func removeHighlight(_ highlight: Highlight) {
        var highlights = loadHighlights()
        highlights.removeAll { $0.range == highlight.range && $0.page == highlight.page }
        if let data = try? JSONEncoder().encode(highlights) {
            UserDefaults.standard.set(data, forKey: highlightsKey)
        }
    }

    func saveAllHighlights(_ highlights: [Highlight]) {
        if let data = try? JSONEncoder().encode(highlights) {
            UserDefaults.standard.set(data, forKey: highlightsKey)
        }
    }
    func deleteAllHighlights() {
        UserDefaults.standard.removeObject(forKey: highlightsKey)
    }

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
