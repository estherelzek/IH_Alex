//
//  ReferenceClass.swift
//  IH_Alex
//
//  Created by esterelzek on 26/02/2025.
//

import Foundation
import UIKit

class ParseReference {
    func invoke(
        spannedText: NSMutableAttributedString,
        parsedTag: ParsedElement,
        metadata: MetaDataResponse,
        book: Book
    ) -> NSMutableAttributedString {
        let refColor = UIColor(hex: "FBB04C")
        let smallFont = UIFont.systemFont(ofSize: UIFont.systemFontSize * 0.7)

        guard case let .reference(_, id) = parsedTag else {
            return spannedText
        }

        // 🔢 Append just [id]
        let displayText = "[\(id)]"
        let attrText = NSMutableAttributedString(string: displayText)

        let range = NSRange(location: 0, length: attrText.length)
        attrText.addAttribute(.foregroundColor, value: refColor, range: range)
        attrText.addAttribute(.font, value: smallFont, range: range)
        attrText.addAttribute(.init("ReferenceID"), value: id, range: range)

        // Optional: add .link attribute if you plan to intercept taps like internal links
        attrText.addAttribute(.link, value: "reference:\(id)", range: range)

        spannedText.append(attrText)

        return spannedText
    }
}

