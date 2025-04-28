//
//  InternalLink.swift
//  IH_Alex
//
//  Created by esterelzek on 26/02/2025.
//
import Foundation
import UIKit

class ParseInternalLink {
    
    func invoke(
        spannedText: NSMutableAttributedString,
        parsedTag: ParsedElement,
        metadata: MetaDataResponse,
        book: Book
    ) -> NSMutableAttributedString {
        let start = spannedText.length
        switch parsedTag {
        case let .internalLinkSource(content, key):
            spannedText.append(NSAttributedString(string: content))
            let end = spannedText.length
            // Instead of normal link, attach custom attribute for internal link
            spannedText.addAttribute(.init("InternalLinkID"), value: key, range: NSRange(location: start, length: end - start))
        default:
            break
        }
        return spannedText
    }
}
