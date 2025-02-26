//
//  WebLinkClass.swift
//  IH_Alex
//
//  Created by esterelzek on 26/02/2025.
//

import Foundation

class ParseWebLink {

    func invoke(spannedText: NSMutableAttributedString, parsedTag: ParsedElement) -> NSMutableAttributedString {
        let start = spannedText.length
        switch parsedTag {
        case let .webLink(content):
            spannedText.append(NSAttributedString(string: content))
            let end = spannedText.length
            let url = URL(string: content)  // Assuming `content` is the web link URL
             if let url = url {
                spannedText.addAttribute(.link, value: url, range: NSRange(location: start, length: end - start))
            }
        default:
            break
        }
        
        return spannedText
    }
    
}

class ReferenceClickableSpan: NSObject {
    
    let parsedTag: String
   // let uiStateViewModel: UiStateViewModel
    
    init(parsedTag: String) {
        self.parsedTag = parsedTag
      //  self.uiStateViewModel = uiStateViewModel
    }
//    func onClick() {
//        uiStateViewModel.setReferenceContent(parsedTag)
//        uiStateViewModel.setIsReferenceClicked(true)
//    }
}
