//
//  BookmarkManager.swift
//  IH_Alex
//
//  Created by Esther Elzek on 04/03/2025.
//
// 📌 Bookmark Model

import Foundation

struct Bookmark: Codable {
    let originalPageIndex: Int
    var isHalfFilled: Bool
}


class BookmarkManager {
    static let shared = BookmarkManager()
    private let bookmarksKey = "bookBookmarks"

    func saveBookmark(_ bookmark: Bookmark) {
        var bookmarks = loadBookmarks()
        if !bookmarks.contains(where: { $0.originalPageIndex == bookmark.originalPageIndex }) {
            bookmarks.append(bookmark)
            saveAllBookmarks(bookmarks)
            print("✅ Bookmark added for original page: \(bookmark.originalPageIndex)")
        }
        printAllBookmarks()
    }

    func removeBookmark(forOriginalPage originalPageIndex: Int) {
        var bookmarks = loadBookmarks()
        if bookmarks.contains(where: { $0.originalPageIndex == originalPageIndex }) {
            bookmarks.removeAll { $0.originalPageIndex == originalPageIndex }
            saveAllBookmarks(bookmarks)
            print("❌ Bookmark removed for original page: \(originalPageIndex)")
        }
        printAllBookmarks()
    }

    func updateBookmark(forOriginalPage originalPageIndex: Int, isHalfFilled: Bool) {
        var bookmarks = loadBookmarks()
        if let index = bookmarks.firstIndex(where: { $0.originalPageIndex == originalPageIndex }) {
            bookmarks[index].isHalfFilled = isHalfFilled
            saveAllBookmarks(bookmarks)
            print("🔄 Bookmark updated for original page: \(originalPageIndex), Half-filled: \(isHalfFilled)")
        }
        printAllBookmarks()
    }

    func loadBookmarks() -> [Bookmark] {
        guard let data = UserDefaults.standard.data(forKey: bookmarksKey),
              let bookmarks = try? JSONDecoder().decode([Bookmark].self, from: data) else {
            return []
        }
        return bookmarks
    }

    func isBookmarked(originalPageIndex: Int) -> Bool {
        return loadBookmarks().contains { $0.originalPageIndex == originalPageIndex }
    }

    func isHalfFilled(originalPageIndex: Int) -> Bool {
        return loadBookmarks().first(where: { $0.originalPageIndex == originalPageIndex })?.isHalfFilled ?? false
    }

    private func saveAllBookmarks(_ bookmarks: [Bookmark]) {
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: bookmarksKey)
        }
    }

    private func printAllBookmarks() {
        let pages = loadBookmarks().map { $0.originalPageIndex }
        if pages.isEmpty {
            print("📜 No bookmarks set.")
        } else {
            print("📌 Currently bookmarked original pages: \(pages.sorted())")
        }
    }
}

