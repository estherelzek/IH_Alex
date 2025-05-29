//
//  HighlightManager.swift
//  IH_Alex
//
//  Created by Esther Elzek on 04/03/2025.
//

import Foundation
import UIKit

import Foundation

class HighlightManager {
    static let shared = HighlightManager()
    private let highlightsKey = "bookHighlights"

    func saveHighlight(_ highlight: Highlight) {
        var highlights = loadHighlights()
        highlights.append(highlight)
        saveAllHighlights(highlights)
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
        highlights.removeAll {
            $0.bookId == highlight.bookId &&
            $0.chapterNumber == highlight.chapterNumber &&
            $0.pageNumberInChapter == highlight.pageNumberInChapter &&
            $0.start == highlight.start &&
            $0.end == highlight.end
        }
        saveAllHighlights(highlights)
    }

    func saveAllHighlights(_ highlights: [Highlight]) {
        if let data = try? JSONEncoder().encode(highlights) {
            UserDefaults.standard.set(data, forKey: highlightsKey)
        }
    }

    func deleteAllHighlights() {
        UserDefaults.standard.removeObject(forKey: highlightsKey)
    }

    /// Optionally filter highlights for a chapter or pages
    func loadHighlights(for chapterNumber: Int) -> [Highlight] {
        return loadHighlights().filter { $0.chapterNumber == chapterNumber }
    }

    /// Load highlights for a list of page numbers in a chapter
    func loadHighlights(for chapterNumber: Int, pages: [Int]) -> [Highlight] {
        return loadHighlights().filter {
            $0.chapterNumber == chapterNumber && pages.contains($0.pageNumberInChapter)
        }
    }
}
