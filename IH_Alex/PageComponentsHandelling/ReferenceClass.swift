//
//  ReferenceClass.swift
//  IH_Alex
//
//  Created by esterelzek on 26/02/2025.
//

import Foundation
import UIKit

//internalLinkTarget
class ParseReference {

    func invoke(parsedTag: String, id: String, spannedText: NSMutableAttributedString) -> NSMutableAttributedString {
        let refColor = UIColor(hex: "FBB04C")
        let start = spannedText.length
        spannedText.append(NSAttributedString(string: "[\(id)]"))
        let end = spannedText.length

        let refSpan = ReferenceClickableSpan(parsedTag: parsedTag)
        spannedText.addAttribute(.link, value: refSpan, range: NSRange(location: start, length: end - start))
        
        return spannedText
    }
}
