//
//  InternalLink.swift
//  IH_Alex
//
//  Created by esterelzek on 26/02/2025.
//

import Foundation

class ParseInternalLink {
    func invoke(spannedText: NSMutableAttributedString, parsedTag: ParsedElement, metadata: MetaDataResponse, book: Book) -> NSMutableAttributedString {
 let start = spannedText.length
        switch parsedTag {
        case let .internalLinkSource(content, key):
            spannedText.append(NSAttributedString(string: content))
            let end = spannedText.length
            let internalLinkID = key // Assuming `key` is a unique identifier for internal links
            let internalLink = InternalLinkClickableSpan(id: internalLinkID)
            spannedText.addAttribute(.link, value: internalLink, range: NSRange(location: start, length: end - start))
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
