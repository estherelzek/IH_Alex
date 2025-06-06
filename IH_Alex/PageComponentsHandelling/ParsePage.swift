//
//  ParsePage.swift
//  IH_Alex
//
//  Created by esterelzek on 18/02/2025.
//

import Foundation
import UIKit

// esther elzek upload
class ParsePage {
    var pageReference: [PageReference]? = nil

    func invoke(pageEncodedString: String, metadata: MetaDataResponse, book: Book) -> [NSMutableAttributedString] {
        guard let encoding = metadata.decodedEncoding() else {
            print("❌ Error decoding encoding")
            return []
        }

        var pages: [NSMutableAttributedString] = []
        var currentPage = NSMutableAttributedString()
        var currentText = ""
        var start = 0
        var isInsideTag = false
        var currentTag: String? = nil
        let tagStart = "##"
        let tagEnd = "@@"
        var i = 0
        let chars = Array(pageEncodedString)
        var countpages = 0
        while i < chars.count {
            let char = chars[i]
          // print("pageEncodedString: \(pageEncodedString)")
            if char == "#" && i + 1 < chars.count && chars[i + 1] == "#" {
                appendCurrentText(to: currentPage, text: &currentText)
                i += 2 // Skip ##
                isInsideTag = true
                start = currentPage.length

                if i < chars.count {
                    let tagChar = chars[i]
                    i += 1
                    switch tagChar {
                    case "P": // ✅ Page Split Tag
                        countpages += 1
                        appendCurrentText(to: currentPage, text: &currentText)
                        if currentPage.length > 0 {
                            pages.append(currentPage)
                        }
                        currentPage = NSMutableAttributedString() // Start new page
                        isInsideTag = false
                        
                    case "I": // ✅ Image Handling
                        var base64String = ""
                        while i < chars.count, !(chars[i] == "@" && i + 1 < chars.count && chars[i + 1] == "@") {
                            base64String.append(chars[i])
                            i += 1
                        }
                        let components = base64String.split(separator: ":")
                        guard components.count >= 3 else {
                            print("⚠️ Invalid image format: \(base64String)")
                            currentPage.append(NSAttributedString(string: "[Invalid Image]", attributes: [.foregroundColor: UIColor.red]))
                            break
                        }
                        let base64Data = components.dropLast(2).joined(separator: ":")
                        let ratio = Int(components[components.count - 2]) ?? 50
                        let alignment = ParseImage().parseAlignment(String(components.last!))
                        if let imageData = Data(base64Encoded: base64Data, options: .ignoreUnknownCharacters) {
                            let imageElement = ParsedElement.image(content: imageData, alignment: alignment, ratio: ratio)
                            ParseImage().invoke(parsedTag: imageElement, spannedText: currentPage)
                        } else {
                            print("⚠️ Invalid Base64 image data")
                            currentPage.append(NSAttributedString(string: "[Invalid Image]", attributes: [.foregroundColor: UIColor.red]))
                        }
                        isInsideTag = false

                    case "W": // ✅ Web Link Handling using ParseWebLink
                        var linkText = ""
                        while i < chars.count, !(chars[i] == "@" && i + 1 < chars.count && chars[i + 1] == "@") {
                            linkText.append(chars[i])
                            i += 1
                        }
                        let webLinkElement = ParsedElement.webLink(content: linkText)
                        currentPage = ParseWebLink().invoke(spannedText: currentPage, parsedTag: webLinkElement)
                        isInsideTag = false
                        
                    case "L":
                        var targetID = ""
                        var referenceTitle = ""

                        // Read targetID (until space)
                        while i < chars.count, chars[i] != " " {
                            targetID.append(chars[i])
                            i += 1
                        }

                        // Skip space
                        if i < chars.count, chars[i] == " " {
                            i += 1
                        }

                        // Read referenceTitle (until "@@")
                        while i + 1 < chars.count, !(chars[i] == "@" && chars[i+1] == "@") {
                            referenceTitle.append(chars[i])
                            i += 1
                        }

                        if referenceTitle.isEmpty {
                            referenceTitle = "[Reference]"
                        }

                        let linkText = referenceTitle

                        let internalLinkElement = ParsedElement.internalLinkSource(content: linkText, key: targetID)
                        currentPage = ParseInternalLink().invoke(spannedText: currentPage, parsedTag: internalLinkElement, metadata: metadata, book: book)

                        // Set the clickable link attribute
                        let range = NSRange(location: start, length: currentPage.length - start)
                        currentPage.addAttribute(.link, value: "internal:\(targetID)", range: range)

                        print("✅ Inserted internal link '\(linkText)' pointing to '\(targetID)'")

                        isInsideTag = false


                    default:
                        currentTag = String(tagChar)
                    }
                }
                continue
            }
            if char == "@" && i + 1 < chars.count && chars[i + 1] == "@" {
                i += 2
                if isInsideTag, let tag = currentTag, encoding.fonts[tag] != nil {
                    appendCurrentText(to: currentPage, text: &currentText)
                    let end = currentPage.length
                    if end > start {
                        FontStyler.applyFontCustomizations(to: currentPage, fontTag: tag, start: start, end: end, fonts: encoding.fonts)
                    }
                }
                isInsideTag = false
                currentTag = nil
                continue
            }
            currentText.append(char)
            i += 1
        }
        
        appendCurrentText(to: currentPage, text: &currentText)
        if currentPage.length > 0 {
            pages.append(currentPage)
        }
      //  print("count: \(pages.count)")
       // print("countpages: \(countpages)")
        return pages
    }

    private func appendCurrentText(to attributedString: NSMutableAttributedString, text: inout String) {
        if !text.isEmpty {
            attributedString.append(NSAttributedString(string: text))
            text = ""
        }
    }
}

enum ParsedElement {
    case text(content: String)
    case font(content: String, fontTag: String)
    case webLink(content: String)
    case internalLinkSource(content: String, key: String)
    case image(content: Data, alignment: NSTextAlignment, ratio: Int)
    case reference(content: String, id: String)
}



