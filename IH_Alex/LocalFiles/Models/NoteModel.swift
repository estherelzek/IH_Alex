//
//  NoteModel.swift
//  IH_Alex
//
//  Created by Esther Elzek on 27/04/2025.
//

import Foundation

struct Note: Codable {
    var page: Int
    var range: NSRange
    var globalRange: NSRange // New
    var title: String
    var content: String
    var position: CGPoint?

    func toDictionary() -> [String: Any] {
        return [
            "page": page,
            "range": ["location": range.location, "length": range.length],
            "globalRange": ["location": globalRange.location, "length": globalRange.length],
            "title": title,
            "content": content,
            "position": position != nil ? ["x": position!.x, "y": position!.y] : nil
        ].compactMapValues { $0 }
    }

    static func fromDictionary(_ dict: [String: Any]) -> Note? {
        guard let page = dict["page"] as? Int,
              let rangeDict = dict["range"] as? [String: Int],
              let globalRangeDict = dict["globalRange"] as? [String: Int],
              let location = rangeDict["location"],
              let length = rangeDict["length"],
              let globalLocation = globalRangeDict["location"],
              let globalLength = globalRangeDict["length"],
              let title = dict["title"] as? String,
              let content = dict["content"] as? String else { return nil }

        let range = NSRange(location: location, length: length)
        let globalRange = NSRange(location: globalLocation, length: globalLength)

        var position: CGPoint? = nil
        if let positionDict = dict["position"] as? [String: CGFloat],
           let x = positionDict["x"],
           let y = positionDict["y"] {
            position = CGPoint(x: x, y: y)
        }

        return Note(page: page, range: range, globalRange: globalRange, title: title, content: content, position: position)
    }

    func withUpdatedRange(_ newRange: NSRange) -> Note {
        var updated = self
        updated.range = newRange
        return updated
    }
}
