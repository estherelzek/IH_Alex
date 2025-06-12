//
//  ImageClass.swift
//  IH_Alex
//
//  Created by esterelzek on 24/02/2025.
//

import Foundation
import UIKit

class ParseImage {
    func invoke(
        parsedTag: ParsedElement,
        spannedText: NSMutableAttributedString
    ) -> NSMutableAttributedString {
        switch parsedTag {
        case .image(let content, let alignment, let ratio):
            let start = spannedText.length
            let validRatio = (Int(ratio) ) + 20
            let imageAttachment = addPhoto(
                alignment: alignment,
                imageData: content,
                ratio: validRatio
            )
            
            let imageAttributedString = NSMutableAttributedString(attachment: imageAttachment)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = alignment  // Explicitly set the alignment
            imageAttributedString.addAttributes([.paragraphStyle: paragraphStyle], range: NSRange(location: 0, length: imageAttributedString.length))
            spannedText.append(imageAttributedString)
            
            let range = NSRange(location: start, length: 1)
            spannedText.addAttribute(.link, value: "imageTapped", range: range)

        default:
            break
        }
        return spannedText
    }
    
    private func addPhoto(alignment: NSTextAlignment, imageData: Data, ratio: Int) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        if let image = UIImage(data: imageData) {
            let screenWidth = UIScreen.main.bounds.width
            let resizedWidth = screenWidth * CGFloat(ratio) / 100
            let resizedHeight = resizedWidth * image.size.height / image.size.width
            
            let resizedImage = image.resized(to: CGSize(width: resizedWidth, height: resizedHeight))
            attachment.image = resizedImage
        }
        return attachment
    }
    
    func parseAlignment(_ alignmentString: String) -> NSTextAlignment {
        let cleanedAlignment = alignmentString
            .trimmingCharacters(in: .whitespacesAndNewlines) // ✅ Remove spaces & newlines
        print("alignmentString cleaned: '\(cleanedAlignment)'")
        
        switch cleanedAlignment {
        case "L": return .left
        case "C": return .center
        case "R": return .right
        case "S": return isRTL() ? .right : .left
        case "E": return isRTL() ? .left : .right
        default:
            print("⚠️ Unrecognized alignment: '\(cleanedAlignment)', defaulting to Center")
            return .center
        }
    }

    func isRTL() -> Bool {
        var isRTL = false
            isRTL = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
        return isRTL
    }

}

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage ?? self
    }
}
