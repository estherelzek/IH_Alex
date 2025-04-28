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

extension MetaDataResponse {
    static let `default` = MetaDataResponse(
        bookID: 0,
        encoding: "",
        index: "",
        targetLinks: ""
    )
}
