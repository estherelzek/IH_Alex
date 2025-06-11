//
//  BookMetaData.swift
//  IH_Alex
//
//  Created by esterelzek on 17/02/2025.
//

import Foundation

struct MetaDataResponse: Codable {
    let bookID: Int
    let encoding: String  // JSON string that needs manual decoding
    let index: String     // JSON string that needs manual decoding
    let targetLinks: String

    enum CodingKeys: String, CodingKey {
        case bookID = "book_id"
        case encoding
        case index
        case targetLinks = "target_links"
    }

    // Decode encoding JSON string into Encoding struct
    func decodedEncoding() -> Encoding? {
        guard let data = encoding.data(using: .utf8) else { return nil }
        do {
            return try JSONDecoder().decode(Encoding.self, from: data)
        } catch {
            print("❌ Error decoding encoding: \(error)")
            return nil
        }
    }

    func decodedIndex() -> [BookIndex]? {
        guard let data = index.data(using: .utf8) else { return nil }
        do {
            return try JSONDecoder().decode([BookIndex].self, from: data)
        } catch {
            print("❌ Error decoding index: \(error)")
            return nil
        }
    }
}
struct Encoding: Codable {
    let tags: Tags
    let fonts: [String: FontStyle]
}

struct Tags: Codable {
    let tagStart, tagEnd: String
    let tagLength, formatLength, linkKeyLength: Int
    let webLink, internalLink, internalLinkTarget, image: String
    let reference, pageTag, chapterTag, splitTag: String
    let splitterTag: String? // <-- Add this line
}

struct FontStyle: Codable {
    let bold, italic: String
    let size: String
    let fontColor, backgroundColor: String
    let align, underline, name: String?
    let fontFamilyName: String?
}

extension MetaDataResponse {
    static let `default` = MetaDataResponse(
        bookID: 0,
        encoding: "",
        index: "",
        targetLinks: ""
    )
}

struct BookIndex: Codable {
    let name: String
    let number: Int
    let pageNumber: Int
    let chapterPagesCount: Int?

    enum CodingKeys: String, CodingKey {
        case name, number, pageNumber, chapterPagesCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        number = try container.decode(Int.self, forKey: .number)
        pageNumber = try container.decode(Int.self, forKey: .pageNumber)
        chapterPagesCount = try? container.decode(Int.self, forKey: .chapterPagesCount)
    }
}
