//
//  InternalLink.swift
//  IH_Alex
//
//  Created by esterelzek on 26/02/2025.
//
import Foundation
import UIKit

class ParseInternalLink {
    func invoke(spannedText: NSMutableAttributedString, parsedTag: ParsedElement, metadata: MetaDataResponse, book: Book) -> NSMutableAttributedString {
        let start = spannedText.length
        switch parsedTag {
        case let .internalLinkSource(content, key):
            spannedText.append(NSAttributedString(string: content))
            let end = spannedText.length
            spannedText.addAttribute(.link, value: "internal:\(key)", range: NSRange(location: start, length: end - start)) // Add internal link format
        default:
            break
        }
        return spannedText
    }
}


class InternalLinkClickableSpan: NSObject {
    let id: String
//let uiStateViewModel: UiStateViewModel
    
    init(id: String) {
        self.id = id
        //self.uiStateViewModel = uiStateViewModel
    }
//    func onClick() {
//        // Handle internal link click - this could be navigating to a section in the book or updating UI state
//        uiStateViewModel.setInternalLinkContent(id)
//        uiStateViewModel.setIsInternalLinkClicked(true)
//    }
}
