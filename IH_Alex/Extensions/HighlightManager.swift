//
//  HighlightManager.swift
//  IH_Alex
//
//  Created by Esther Elzek on 04/03/2025.
//

import Foundation

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

}
