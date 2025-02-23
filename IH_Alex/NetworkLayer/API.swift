//
//  API.swift
//  IH_Alex
//
//  Created by esterelzek on 17/02/2025.
//

import Foundation

enum API: EndPoint {
    case fetchBooks(userID: Int, limit: Int, offset: Int, since: Int)
    case fetchBookMetadata(bookID: Int)
    case fetchFirstToken(bookID: Int, tokenID: Int)

    var baseURL: String {
        return "http://192.168.1.35:8080"
    }

    var urlSubFolder: String {
        return "/api/v1"
    }

    var path: String {
        switch self {
        case .fetchBooks(let userID, _, _, _):
            return "users/\(userID)/books"
        case .fetchBookMetadata(let bookID):
            return "books/\(bookID)/metadata"
        case .fetchFirstToken(let bookID, let tokenID):
            return "books/\(bookID)/tokens/\(tokenID)"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .fetchBooks(_, let limit, let offset, let since):
            return [
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "offset", value: "\(offset)"),
                URLQueryItem(name: "since", value: "\(since)")
            ]
        default:
            return []
        }
    }

    var method: HTTPMethod {
        return .get
    }

    var body: [String: Any]? {
        return nil
    }
}
