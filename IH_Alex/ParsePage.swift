//
//  ParsePage.swift
//  IH_Alex
//
//  Created by esterelzek on 18/02/2025.
//

import Foundation
import UIKit

import Foundation
import UIKit

class ParsePage {
    func invoke(pageEncodedString: String, metadata: MetaDataResponse, book: Book) -> NSMutableAttributedString {
        guard let encoding = metadata.decodedEncoding() else {
            print("❌ Error decoding encoding")
            return NSMutableAttributedString()
        }
        
        let cleanedString = pageEncodedString.replacingOccurrences(of: "##", with: "").replacingOccurrences(of: "@@", with: "")
        let attributedString = NSMutableAttributedString()
        var currentText = ""
        var start = attributedString.length
        
        for char in cleanedString {
            switch char {
            case "I":
                appendCurrentText(to: attributedString, text: &currentText)
                attributedString.append(NSAttributedString(string: "[Image]", attributes: [.foregroundColor: UIColor.blue]))
                
            case "L":
                appendCurrentText(to: attributedString, text: &currentText)
                attributedString.append(NSAttributedString(string: "[Link]", attributes: [.foregroundColor: UIColor.systemBlue]))
                
            case "l":
                appendCurrentText(to: attributedString, text: &currentText)
                attributedString.append(NSAttributedString(string: "[Internal Target]", attributes: [.foregroundColor: UIColor.purple]))
                
            default:
                if let fontStyle = encoding.fonts[String(char)] {
                    appendCurrentText(to: attributedString, text: &currentText)
                    let end = attributedString.length
                    applyFontCustomizations(spannable: attributedString, fontTag: String(char), start: start, end: end, fonts: encoding.fonts)
                    start = end
                } else {
                    currentText.append(char)
                }
            }
        }
        
        appendCurrentText(to: attributedString, text: &currentText)
        return attributedString
    }
    
    private func appendCurrentText(to attributedString: NSMutableAttributedString, text: inout String) {
        if !text.isEmpty {
            attributedString.append(NSAttributedString(string: text))
            text = ""
        }
    }
}

func applyFontCustomizations(spannable: NSMutableAttributedString, fontTag: String, start: Int, end: Int, fonts: [String: FontStyle]) {
    guard let fontStyle = fonts[fontTag] else { return }

    var attributes: [NSAttributedString.Key: Any] = [:]
    
    // Set Font Size & Style
    let fontSize = CGFloat(Double(fontStyle.size) ?? 14.0) // Default to 14 if parsing fails
    var font = UIFont.systemFont(ofSize: fontSize)
    print("font: \(fontStyle)")
    if fontStyle.bold == "1" && fontStyle.italic == "1" {
        font = UIFont(descriptor: UIFontDescriptor(name: "Helvetica-BoldOblique", size: fontSize), size: fontSize)
    } else if fontStyle.bold == "1" {
        font = UIFont.boldSystemFont(ofSize: fontSize)
    } else if fontStyle.italic == "1" {
        font = UIFont.italicSystemFont(ofSize: fontSize)
    }

    attributes[.font] = font

    // Underline
    if fontStyle.underline == "1" {
        attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
    }

    // Alignment
    if let alignment = fontStyle.align {
        let paragraphStyle = NSMutableParagraphStyle()
        switch alignment {
        case "c": paragraphStyle.alignment = .center
        case "1": paragraphStyle.alignment = .right
        case "0": paragraphStyle.alignment = .left
        default: break
        }
        attributes[.paragraphStyle] = paragraphStyle
    }

    // Font Color
    if fontStyle.fontColor != "0" {
        attributes[.foregroundColor] = UIColor(hex: fontStyle.fontColor)
    }

    // Background Color
    if fontStyle.backgroundColor != "0" {
        attributes[.backgroundColor] = UIColor(hex: fontStyle.backgroundColor)
    }

    // Apply attributes correctly to the range
    let range = NSRange(location: start, length: end - start)
    spannable.addAttributes(attributes, range: range)
}


    private func applyParsedTag(_ parsedTag: ParsedElement, spannedText: NSMutableAttributedString, metadata: MetaDataResponse, book: Book) -> NSMutableAttributedString {
        switch parsedTag {
        case let .text(content):
            return ParseRegularText().invoke(spannedText: spannedText, parsedTag: content)
        case let .reference(content, id):
            return ParseReference().invoke(parsedTag: content, id: id, spannedText: spannedText)
        case let .font(content, fontTag):
            return ParseFont().invoke(metadata: metadata, parsedTag: parsedTag, spannedText: spannedText)
        case let .webLink(content):
            return ParseWebLink().invoke(spannedText: spannedText, parsedTag: parsedTag)
        case let .internalLinkSource(content, key):
            return ParseInternalLink().invoke(spannedText: spannedText, parsedTag: parsedTag, metadata: metadata, book: book)
        case let .image(content, alignment, ratio):
            print("This is an image with alignment: \(alignment) and ratio: \(ratio)")
        }
        return spannedText
    }

    func parseTag(_ tagContent: String, encoding: Encoding) -> ParsedElement? {
        print("🔍 Parsing tagContent: \(tagContent)")

        let components = tagContent.split(separator: ":", maxSplits: 1)
        guard let tagType = components.first else {
            print("❌ Invalid tag format: \(tagContent)")
            return nil
        }
        let content = components.count > 1 ? String(components[1]) : ""
        
        print("   ➤ Extracted tagType: \(tagType), Content: \(content)")

        switch tagType {
        case "text":
            return .text(content: content)
        case "font":
            let fontComponents = content.split(separator: ",", maxSplits: 1)
            guard fontComponents.count == 2 else {
                print("❌ Invalid font format: \(content)")
                return nil
            }
            return .font(content: String(fontComponents[1]), fontTag: String(fontComponents[0]))
        case "reference":
            let refComponents = content.split(separator: ",", maxSplits: 1)
            guard refComponents.count == 2 else {
                print("❌ Invalid reference format: \(content)")
                return nil
            }
            return .reference(content: String(refComponents[1]), id: String(refComponents[0]))
        case "weblink":
            return .webLink(content: content)
        case "internal":
            let internalComponents = content.split(separator: ",", maxSplits: 1)
            guard internalComponents.count == 2 else {
                print("❌ Invalid internal link format: \(content)")
                return nil
            }
            return .internalLinkSource(content: String(internalComponents[1]), key: String(internalComponents[0]))
        default:
            print("❌ Unknown tagType: \(tagType)")
            return nil
        }
    }

class ParseFont {
    func invoke(metadata: MetaDataResponse, parsedTag: ParsedElement, spannedText: NSMutableAttributedString) -> NSMutableAttributedString {
        let start = spannedText.length
        
        switch parsedTag {
        case let .font(content, fontTag):
            let fontText = NSAttributedString(string: content)
            spannedText.append(fontText)
            let end = spannedText.length
            
            guard let encoding = metadata.decodedEncoding() else {
                print("❌ Error decoding encoding")
                return spannedText
            }
            
            applyFontCustomizations(spannable: spannedText, fontTag: fontTag, start: start, end: end, fonts: encoding.fonts)
            
        default:
            break
        }
        
        return spannedText
    }
}


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
class ParseImage {

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

class ParseRegularText {

    func invoke(spannedText: NSMutableAttributedString, parsedTag: String) -> NSMutableAttributedString {
        spannedText.append(NSAttributedString(string: parsedTag))
        return spannedText
    }
}

enum ParsedElement {
    case text(content: String)
    case font(content: String, fontTag: String)
    case webLink(content: String)
    case internalLinkSource(content: String, key: String)
    case image(content: Data, alignment: String, ratio: Int)
    case reference(content: String, id: String)
}

extension UIColor {
    convenience init(hex: String) {
        let hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hexSanitized)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgb & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }
}

