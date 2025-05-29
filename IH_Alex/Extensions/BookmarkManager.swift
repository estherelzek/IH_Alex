//
//  BookmarkManager.swift
//  IH_Alex
//
//  Created by Esther Elzek on 04/03/2025.
//
// 📌 Bookmark Model

import Foundation

class BookmarkManager {
    static let shared = BookmarkManager()
    private let bookmarksKey = "bookBookmarks"

    // MARK: - Save Bookmark
    func saveBookmark(_ bookmark: Bookmark) {
        var bookmarks = loadBookmarks()

        let isAlreadySaved = bookmarks.contains {
            $0.bookId == bookmark.bookId &&
            $0.chapterNumber == bookmark.chapterNumber &&
            $0.pageNumberInChapter == bookmark.pageNumberInChapter
        }

        if !isAlreadySaved {
            bookmarks.append(bookmark)
            saveAllBookmarks(bookmarks)
            print("✅ Bookmark added for Book ID \(bookmark.bookId), Page \(bookmark.pageNumberInBook)")
        } else {
            print("⚠️ Bookmark already exists for Book ID \(bookmark.bookId), Page \(bookmark.pageNumberInBook)")
        }

        printAllBookmarks()
    }

    // MARK: - Remove Bookmark
    func removeBookmark(bookId: Int, chapterNumber: Int, pageNumberInChapter: Int) {
        var bookmarks = loadBookmarks()
        let originalCount = bookmarks.count

        bookmarks.removeAll {
            $0.bookId == bookId &&
            $0.chapterNumber == chapterNumber &&
            $0.pageNumberInChapter == pageNumberInChapter
        }

        if bookmarks.count < originalCount {
            saveAllBookmarks(bookmarks)
            print("❌ Bookmark removed for Book ID \(bookId), Chapter \(chapterNumber), Page \(pageNumberInChapter)")
        }

        printAllBookmarks()
    }

    // MARK: - Load Bookmarks
    func loadBookmarks() -> [Bookmark] {
        guard let data = UserDefaults.standard.data(forKey: bookmarksKey),
              let bookmarks = try? JSONDecoder().decode([Bookmark].self, from: data) else {
            return []
        }
        return bookmarks
    }

    // MARK: - Check if Page is Bookmarked
    func isBookmarked(bookId: Int, chapterNumber: Int, pageNumberInChapter: Int) -> Bool {
        return loadBookmarks().contains {
            $0.bookId == bookId &&
            $0.chapterNumber == chapterNumber &&
            $0.pageNumberInChapter == pageNumberInChapter
        }
    }

    // MARK: - Get All Bookmarked Pages for Book
    func getAllBookmarkedPages(bookId: Int) -> [Bookmark] {
        return loadBookmarks().filter { $0.bookId == bookId }
    }

    // MARK: - Save All
    private func saveAllBookmarks(_ bookmarks: [Bookmark]) {
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: bookmarksKey)
        }
    }

    // MARK: - Debug
    private func printAllBookmarks() {
        let bookmarks = loadBookmarks()
        if bookmarks.isEmpty {
            print("📜 No bookmarks set.")
        } else {
            for bm in bookmarks.sorted(by: { $0.pageNumberInBook < $1.pageNumberInBook }) {
                print("📌 Book ID: \(bm.bookId), Chapter: \(bm.chapterNumber), Page: \(bm.pageNumberInChapter), Text: \"\(bm.text)\"")
            }
        }
    }
}
