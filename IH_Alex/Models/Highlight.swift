//
//  Highlight.swift
//  IH_Alex
//
//  Created by Esther Elzek on 04/03/2025.
//

import Foundation

//struct Highlight: Codable {
//    let text: String
//    let range: NSRange
//    let color: String
//    let page: Int
//    
//    enum CodingKeys: String, CodingKey {
//        case text, color, page
//        case start, length
//    }
//
//    init(text: String, range: NSRange, color: String, page: Int) {
//        self.text = text
//        self.range = range
//        self.color = color
//        self.page = page
//    }
//
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(text, forKey: .text)
//        try container.encode(color, forKey: .color)
//        try container.encode(page, forKey: .page)
//        try container.encode(range.location, forKey: .start)
//        try container.encode(range.length, forKey: .length)
//    }
//
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        text = try container.decode(String.self, forKey: .text)
//        color = try container.decode(String.self, forKey: .color)
//        page = try container.decode(Int.self, forKey: .page)
//        let start = try container.decode(Int.self, forKey: .start)
//        let length = try container.decode(Int.self, forKey: .length)
//        range = NSRange(location: start, length: length)
//    }
//}
