//
//  FontClass.swift
//  IH_Alex
//
//  Created by esterelzek on 26/02/2025.
//

import Foundation
import UIKit

class FontStyler {
    static func applyFontCustomizations(
        to spannable: NSMutableAttributedString,
        fontTag: String,
        start: Int,
        end: Int,
        fonts: [String: FontStyle]
    ) {
        guard let fontStyle = fonts[fontTag], end > start else {
            print("Invalid range or missing font style for tag: \(fontTag)")
            return
        }

        var attributes: [NSAttributedString.Key: Any] = [:]
        let fontSize = CGFloat(Double(fontStyle.size) ?? 14.0) // Default to 14 if parsing fails
        var font: UIFont?
        if fontStyle.bold == "1" && fontStyle.italic == "1" {
            font = UIFont(name: "Cairo-BoldItalic", size: fontSize) ?? UIFont.boldSystemFont(ofSize: fontSize)
        } else if fontStyle.bold == "1" {
            font = UIFont(name: "Cairo-Bold", size: fontSize) ?? UIFont.boldSystemFont(ofSize: fontSize)
        } else if fontStyle.italic == "1" {
            font = UIFont(name: "Cairo-Regular", size: fontSize) ?? UIFont.italicSystemFont(ofSize: fontSize)
        } else {
            font = UIFont(name: "Cairo-Regular", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
        }

        if let finalFont = font {
            attributes[.font] = finalFont
        }
        if fontStyle.underline == "1" {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        let paragraphStyle = NSMutableParagraphStyle()
        if let alignment = fontStyle.align {
           // print("alignment: \(alignment)")
            switch alignment {
            case "c":
                paragraphStyle.alignment = .center
            case "r":
                paragraphStyle.alignment = .right
            case "l":
                paragraphStyle.alignment = .left
            case "j":
                paragraphStyle.alignment = .justified
                let textSegment = (spannable.string as NSString).substring(with: NSRange(location: start, length: end - start))
                paragraphStyle.baseWritingDirection = isArabic(text: textSegment) ? .rightToLeft : .leftToRight
            default:
                break
            }
        } else {
            let textSegment = (spannable.string as NSString).substring(with: NSRange(location: start, length: end - start))
            paragraphStyle.alignment = isArabic(text: textSegment) ? .right : .left
            paragraphStyle.baseWritingDirection = isArabic(text: textSegment) ? .rightToLeft : .leftToRight
        }

        attributes[.paragraphStyle] = paragraphStyle
        if fontStyle.fontColor != "0" {
            attributes[.foregroundColor] = UIColor(hex: fontStyle.fontColor)
        }
        if fontStyle.backgroundColor != "0" {
            attributes[.backgroundColor] = UIColor(hex: fontStyle.backgroundColor)
        }
        if end > start {
            let range = NSRange(location: start, length: end - start)
            guard range.location + range.length <= spannable.length else {
                print("Invalid range: \(range) for text length: \(spannable.length)")
                return
            }
            let affectedText = (spannable.string as NSString).substring(with: range)
            // print("🎨 Applying attributes to: '\(affectedText)' at range: \(range)")
            spannable.addAttributes(attributes, range: range)
        }
    }
     static func isArabic(text: String) -> Bool {
        let arabicRange = text.range(of: "\\p{Arabic}", options: .regularExpression)
        return arabicRange != nil
    }
}

class ParseRegularText {
    func invoke(spannedText: NSMutableAttributedString, parsedTag: String) -> NSMutableAttributedString {
        spannedText.append(NSAttributedString(string: parsedTag))
        return spannedText
    }
}
