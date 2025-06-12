//
//  Extensions.swift
//  IH_Alex
//
//  Created by esterelzek on 17/02/2025.
//

import Foundation
import Foundation
import UIKit

class Decryptor {
    
    let IMAGE_SPLITTER = "!@D%#^$@@#BFSA#$"
    let IMAGE_NAME_SPLITTER = "!@D%#^$#BFSA#$"

    func decryption(txt: String, id: Int) -> String {
        print("decryption is called")
        let contents = txt.split(separator: IMAGE_NAME_SPLITTER)
        var decryptionTxt = ""
        print("contents[i] = \(contents.count)")
        for i in stride(from: 0, to: contents.count, by: 2) {
            decryptionTxt += decrypt(text: String(contents[i]))
            if i < contents.count - 1 {
                decryptionTxt += String(contents[i + 1]) // image
            }
        }
        return decryptionTxt
    }

    private func decrypt(text: String) -> String {
        var decryptedText = ""
        print("decrypt is called text size = \(text.count)")
        for scalar in text.unicodeScalars {
            let decryptedScalar = UnicodeScalar(scalar.value - 5) ?? scalar
            decryptedText.append(Character(decryptedScalar))
        }
        return decryptedText
    }
    
    static func isArabic(text: String) -> Bool {
       let arabicRange = text.range(of: "\\p{Arabic}", options: .regularExpression)
       return arabicRange != nil
   }
}

extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexSanitized.hasPrefix("#") {
            hexSanitized = String(hexSanitized.dropFirst())
        }
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

extension UIColor {
    func components() -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if self.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return (r, g, b, a)
        }
        return nil
    }
}

extension UserDefaults {
    func setColor(_ color: UIColor, forKey key: String) {
        let colorData = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
        set(colorData, forKey: key)
    }

    func color(forKey key: String) -> UIColor? {
        guard let colorData = data(forKey: key),
              let color = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? UIColor else {
            return nil
        }
        return color
    }
}

extension TextPageViewController {
    func setupCustomMenu() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(showTextOptionsAlert(_:)))
        textView.addGestureRecognizer(longPressGesture)
        textView.isUserInteractionEnabled = true
        textView.isEditable = false
        textView.isSelectable = true
    }
    
    @objc func showTextOptionsAlert(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let menuVC = CustomMenuViewController()
        menuVC.modalPresentationStyle = .overCurrentContext
        menuVC.modalTransitionStyle = .crossDissolve
        menuVC.delegate = self
        if let selectedRange = textView.selectedTextRange {
            let selectionRect = textView.firstRect(for: selectedRange) // Get bounding rect
            let convertedRect = textView.convert(selectionRect, to: view) // Convert to screen coordinates
            let menuHeight: CGFloat = 50
            let yOffset = max(convertedRect.minY - menuHeight - 10, view.safeAreaInsets.top + 10)
            menuVC.selectedTextFrame = CGRect(x: convertedRect.midX, y: yOffset, width: convertedRect.width, height: convertedRect.height)
        }
        present(menuVC, animated: true)
    }

}

extension Notification.Name {
    static let didCloseMenuAndRequestRefresh = Notification.Name("didCloseMenuAndRequestRefresh")
}
extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension TextPageViewController {
  
    
    func createColorImage(color: UIColor) -> UIImage? {
        let size = CGSize(width: 20, height: 20)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        color.setFill()
        context?.fillEllipse(in: CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
          func calculateHeight() -> CGFloat {
              let width = UIScreen.main.bounds.width - 40
              let targetSize = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
              let estimatedSize = textView.sizeThatFits(targetSize)
              return estimatedSize.height
          }

    func applyLanguageBasedAlignment(to attributedText: NSAttributedString) -> NSAttributedString {
        let mutableAttributedText = NSMutableAttributedString(attributedString: attributedText)
        mutableAttributedText.enumerateAttributes(in: NSRange(location: 0, length: mutableAttributedText.length), options: []) { attributes, range, _ in
            if attributes[.paragraphStyle] == nil {
                let textSegment = (mutableAttributedText.string as NSString).substring(with: range)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = isArabic(text: textSegment) ? .right : .left
                mutableAttributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
            }
        }
        return mutableAttributedText
    }
    
    func isArabic(text: String) -> Bool {
       let arabicRange = text.range(of: "\\p{Arabic}", options: .regularExpression)
       return arabicRange != nil
   }
}
extension UIColor {
    func toHexInt() -> Int {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: nil)
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        return (r << 16) + (g << 8) + b
    }

    convenience init(rgb: Int) {
        let red = CGFloat((rgb >> 16) & 0xFF) / 255
        let green = CGFloat((rgb >> 8) & 0xFF) / 255
        let blue = CGFloat(rgb & 0xFF) / 255
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}


extension NSRange {
    func expanded(to characters: Int, in text: String) -> NSRange {
        let start = max(location - characters, 0)
        let end = min(location + length + characters, text.count)
        return NSRange(location: start, length: end - start)
    }
}
extension String {
    func ranges(of searchString: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var start = startIndex
        while let range = self[start...].range(of: searchString) {
            ranges.append(range)
            start = range.upperBound
        }
        return ranges
    }

    func snippet(around range: Range<String.Index>, radius: Int) -> String {
        let lower = index(range.lowerBound, offsetBy: -radius, limitedBy: startIndex) ?? startIndex
        let upper = index(range.upperBound, offsetBy: radius, limitedBy: endIndex) ?? endIndex
        return String(self[lower..<upper])
    }
}
extension PagedTextViewController {
    func loadRawChapters(completion: @escaping () -> Void) {
        let dispatchGroup = DispatchGroup()
        var bookLoaded = false
        var metadataLoaded = false
        dispatchGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            if let bookInfo: BookResponse = self.loadJSON(from: "Bookinfo", as: BookResponse.self) {
                self.bookResponse = bookInfo
                bookLoaded = true
                print("✅ Book Info loaded.")
            } else {
                print("❌ Failed to load Book Info.")
            }
            dispatchGroup.leave()
        }

        // ✅ Load Metadata
        dispatchGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            if let metadata: MetaDataResponse = self.loadJSON(from: "metadataResponse", as: MetaDataResponse.self) {
                self.metadataa = metadata
                metadataLoaded = true
                print("✅ Metadata loaded.")

                if let targetLinksData = metadata.targetLinks.data(using: .utf8) {
                    do {
                        let targetLinks = try JSONDecoder().decode([TargetLink].self, from: targetLinksData)
                        let pageReferences = targetLinks.map {
                            PageReference(
                                key: $0.key,
                                chapterNumber: $0.chapterNumber,
                                pageNumber: $0.pageNumber,
                                index: $0.index
                            )
                        }
                        self.pageReference = pageReferences
                        if let encoded = try? JSONEncoder().encode(pageReferences) {
                            UserDefaults.standard.set(encoded, forKey: "PageReferencesKey")
                            print("✅ PageReferences saved to UserDefaults.")
                        }

                    } catch {
                        print("❌ Failed to decode targetLinks: \(error.localizedDescription)")
                    }
                }

            } else {
                print("❌ Failed to load Metadata.")
            }
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .global(qos: .userInitiated)) {
            guard bookLoaded, metadataLoaded,
                  let book = self.bookResponse?.book,
                  let metadata = self.metadataa else {
                print("❌ Cannot process chapters: Book or Metadata not ready.")
                DispatchQueue.main.async { completion() }
                return
            }

            let finalFontSize: CGFloat = {
                let value = UserDefaults.standard.float(forKey: "globalFontSize")
                return value > 0 ? CGFloat(value) : 16.0
            }()

            let finalScreenSize: CGSize = {
                let width = UserDefaults.standard.float(forKey: "lastScreenWidth")
                let height = UserDefaults.standard.float(forKey: "lastScreenHeight")
                if width > 0, height > 0 {
                    return CGSize(width: CGFloat(width), height: CGFloat(height))
                } else {
                    return UIScreen.main.bounds.inset(by: UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)).size
                }
            }()
            
            UserDefaults.standard.set(finalFontSize, forKey: "lastFontSize")
            UserDefaults.standard.set(Float(finalScreenSize.width), forKey: "lastScreenWidth")
            UserDefaults.standard.set(Float(finalScreenSize.height), forKey: "lastScreenHeight")

            self.bookChapterrs.removeAll()
            self.pagess.removeAll()
            let tokens = ["token1", "token2", "token3", "token4", "token5", "token6", "token7"]

            var globalPageOffset = 0

            for token in tokens {
                if var chapter: Chapterr = self.loadJSON(from: token, as: Chapterr.self) {
                    let pages = self.generatePagesForChapter(
                        chapter: &chapter,
                        book: book,
                        metadata: metadata,
                        fontSize: finalFontSize,
                        screenSize: finalScreenSize,
                        globalPageOffset: globalPageOffset
                    )
                    globalPageOffset += pages.count
                    self.pagess.append(contentsOf: pages)
                    self.bookChapterrs.append(chapter)
                    print("✅ Processed \(token) → \(pages.count) pages")
                } else {
                    print("❌ Failed to load \(token)")
                }
            }

            self.chunkedPages = self.createChunks(fontSize: finalFontSize, screenSize: finalScreenSize)
            print("✅ Created \(self.chunkedPages.count) chunks")
            DispatchQueue.main.async {
                print("✅ All files loaded, chapters paginated, and chunks created!")
                completion()
            }
        }
    }

    func generatePagesForChapter(
        chapter: inout Chapterr,
        book: Book,
        metadata: MetaDataResponse,
        fontSize: CGFloat,
        screenSize: CGSize,
        globalPageOffset: Int
    ) -> [Page] {
        let decryptor = Decryptor()
        let decryptedText = decryptor.decryption(txt: chapter.content, id: book.id)
        let attributedPages = ParsePage().invoke(
            pageEncodedString: decryptedText,
            metadata: metadata,
            book: book
        )
        if let indexList = metadata.decodedIndex(),
           let matching = indexList.first(where: { $0.number == chapter.firstChapterNumber }) {
            chapter.chapterName = matching.name
        }
        var generatedPages: [Page] = []
        var currentPageNumberInBook = chapter.firstPageNumber
        var currentPageIndexInBook = globalPageOffset
        var pageNumberInChapter = 0
        
        for attributedPage in attributedPages {
            let mutableText = NSMutableAttributedString(attributedString: attributedPage)
            mutableText.addAttribute(.font, value: UIFont.systemFont(ofSize: fontSize), range: NSRange(location: 0, length: mutableText.length))
            
            let chunks = paginate(attributedText: mutableText, fontSize: fontSize, maxSize: screenSize)

            for chunk in chunks {
                let plainText = chunk.text.string
                
                let page = Page(
                    pageNumber: currentPageNumberInBook,
                    pageNumberInChapter: pageNumberInChapter,
                    body: plainText,
                    chapterNumber: chapter.firstChapterNumber,
                    pageIndexInBook: currentPageIndexInBook
                )
                
                generatedPages.append(page)
                currentPageNumberInBook += 1
                currentPageIndexInBook += 1
                pageNumberInChapter += 1
            }
        }
        chapter.pages = generatedPages
        chapter.numberOfPages = generatedPages.count
        
        return generatedPages
    }
    
    func createChunks(fontSize: CGFloat, screenSize: CGSize) -> [Chunk] {
        var chunks: [Chunk] = []
        var globalPageIndex = 0
        var chunkNumber = 0
        var seenChapters: Set<Int> = []

        for content in bookChapterrs {
            let chapterNumber = content.firstChapterNumber

            guard !seenChapters.contains(chapterNumber) else {
                print("⚠️ Skipping duplicate chapter \(chapterNumber)")
                continue
            }
            seenChapters.insert(chapterNumber)

            let decryptor = Decryptor()
            let decryptedText = decryptor.decryption(txt: content.content, id: bookResponse?.book.id ?? 0)

            let parsedPages = ParsePage().invoke(
                pageEncodedString: decryptedText,
                metadata: metadataa ?? MetaDataResponse.default,
                book: bookResponse?.book ?? Book.default
            )

            var localPageIndex = 0

            for attributedText in parsedPages {
                let mutable = NSMutableAttributedString(attributedString: attributedText)
                mutable.addAttribute(.font, value: UIFont.systemFont(ofSize: fontSize), range: NSRange(location: 0, length: mutable.length))

                let pageChunks = paginate(attributedText: mutable, fontSize: fontSize, maxSize: screenSize)
                for chunk in pageChunks {
                    let localStartIndex = chunk.range.location
                    let localEndIndex = localStartIndex + chunk.range.length

                    let newChunk = Chunk(
                        attributedText: chunk.text,
                        image: nil,
                        originalPageIndex: localPageIndex,
                        pageNumberInChapter: localPageIndex,
                        pageNumberInBook: content.firstPageNumber + localPageIndex,
                        chapterNumber: chapterNumber,
                        chunkNumber: chunkNumber,
                        pageIndexInBook: globalPageIndex,
                        rangeInOriginal: chunk.range,
                        globalStartIndex: localStartIndex,  // ✅ Relative to full page
                        globalEndIndex: localEndIndex       // ✅ Relative to full page
                    )

                    chunks.append(newChunk)
                    chunkNumber += 1
                    globalPageIndex += 1
                }


                localPageIndex += 1
            }
        }
        print("chunks.count: \(chunks.count)")
        print("self.pagesss.count: \(self.pagess.count)")
        return chunks
    }


    
}
