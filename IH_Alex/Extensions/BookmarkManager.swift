//
//  BookmarkManager.swift
//  IH_Alex
//
//  Created by Esther Elzek on 04/03/2025.
//
// 📌 Bookmark Model

import Foundation

import Foundation

struct Bookmark: Codable {
    let page: Int
    var isHalfFilled: Bool
}

class BookmarkManager {
    static let shared = BookmarkManager()
    private let bookmarksKey = "bookBookmarks"

    func saveBookmark(_ bookmark: Bookmark) {
        var bookmarks = loadBookmarks()
        if !bookmarks.contains(where: { $0.page == bookmark.page }) {
            bookmarks.append(bookmark)
            saveAllBookmarks(bookmarks)
            print("✅ Bookmark added for page: \(bookmark.page)")
        }
        printAllBookmarks()
    }

    func removeBookmark(forPage page: Int) {
        var bookmarks = loadBookmarks()
        if bookmarks.contains(where: { $0.page == page }) {
            bookmarks.removeAll { $0.page == page }
            saveAllBookmarks(bookmarks)
            print("❌ Bookmark removed for page: \(page)")
        }
        printAllBookmarks()
    }

    func updateBookmark(forPage page: Int, isHalfFilled: Bool) {
        var bookmarks = loadBookmarks()
        if let index = bookmarks.firstIndex(where: { $0.page == page }) {
            bookmarks[index].isHalfFilled = isHalfFilled
            saveAllBookmarks(bookmarks)
            print("🔄 Bookmark updated for page: \(page), Half-filled: \(isHalfFilled)")
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

    private func saveAllBookmarks(_ bookmarks: [Bookmark]) {
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: bookmarksKey)
        }
    }

    func isBookmarked(page: Int) -> Bool {
        return loadBookmarks().contains { $0.page == page }
    }

    func isHalfFilled(page: Int) -> Bool {
        return loadBookmarks().first(where: { $0.page == page })?.isHalfFilled ?? false
    }

    private func printAllBookmarks() {
        let bookmarkedPages = loadBookmarks().map { $0.page }
        if bookmarkedPages.isEmpty {
            print("📜 No bookmarks set.")
        } else {
            print("📌 Currently bookmarked pages: \(bookmarkedPages.sorted())")
        }
    }
}
