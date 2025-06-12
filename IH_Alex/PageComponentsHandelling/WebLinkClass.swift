//
//  WebLinkClass.swift
//  IH_Alex
//
//  Created by esterelzek on 26/02/2025.
//

import Foundation
import UIKit

class ParseWebLink {

    func invoke(spannedText: NSMutableAttributedString, parsedTag: ParsedElement) -> NSMutableAttributedString {
        let start = spannedText.length
        switch parsedTag {
        case let .webLink(content):
            spannedText.append(NSAttributedString(string: content))
            let end = spannedText.length
            if let url = URL(string: content), UIApplication.shared.canOpenURL(url) {
                spannedText.addAttribute(.link, value: url, range: NSRange(location: start, length: end - start))
            }
        default:
            break
        }
        return spannedText
    }
}
