//
//  SearchInBook.swift
//  IH_Alex
//
//  Created by Esther Elzek on 12/05/2025.
//

//import Foundation
//
//class SearchResultManager {
//    static let shared = SearchResultManager()
//    private let searchResultsKey = "bookSearchResults"
//    // Save a single search result
//    func saveSearchResult(_ searchResult: SearchResult) {
//        var searchResults = loadSearchResults()
//        searchResults.append(searchResult)
//        if let data = try? JSONEncoder().encode(searchResults) {
//            UserDefaults.standard.set(data, forKey: searchResultsKey)
//        }
//    }
//    // Load all search results
//    func loadSearchResults() -> [SearchResult] {
//        guard let data = UserDefaults.standard.data(forKey: searchResultsKey),
//              let searchResults = try? JSONDecoder().decode([SearchResult].self, from: data) else {
//            return []
//        }
//        return searchResults
//    }
//    // Save all search results (batch saving)
//    func saveAllSearchResults(_ searchResults: [SearchResult]) {
//        if let data = try? JSONEncoder().encode(searchResults) {
//            UserDefaults.standard.set(data, forKey: searchResultsKey)
//        }
//    }
//    // Clear all search results
//    func clearAllSearchResults() {
//        UserDefaults.standard.removeObject(forKey: searchResultsKey)
//    }
//}

import Foundation

class SearchResultManager {
    
    static let shared = SearchResultManager()
    private let searchResultsKey = "SavedSearchResults"
    private let searchKeywordKey = "SavedSearchKeyword"

    private init() {}
    
    func saveSearchResults(_ results: [SearchResult], keyword: String?) {
        if let data = try? JSONEncoder().encode(results) {
            UserDefaults.standard.set(data, forKey: searchResultsKey)
            UserDefaults.standard.set(keyword, forKey: searchKeywordKey)
        }
    }

    func loadSearchResults() -> ([SearchResult], String?) {
        guard let data = UserDefaults.standard.data(forKey: searchResultsKey),
              let results = try? JSONDecoder().decode([SearchResult].self, from: data) else {
            return ([], nil)
        }
        let keyword = UserDefaults.standard.string(forKey: searchKeywordKey)
        return (results, keyword)
    }

    func clearAllSearchResults() {
        UserDefaults.standard.removeObject(forKey: searchResultsKey)
        UserDefaults.standard.removeObject(forKey: searchKeywordKey)
    }
}
