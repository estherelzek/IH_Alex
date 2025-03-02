//
//  PagedTextViewController.swift
//  IH_Alex
//
//  Created by esterelzek on 16/02/2025.
//

import Foundation
import UIKit
import CloudKit

struct PageContent {
    let attributedText: NSAttributedString
    let image: UIImage?
}

class PagedTextViewController: UIPageViewController, UIPageViewControllerDataSource {
    let pageControl = UIPageControl()
    var pages: [PageContent] = []
    var currentIndex = 0
    var currentBookID: Int?
    var metadataa: MetaDataResponse?
    var bookContent: BookContent?
    var bookResponse: BookResponse?
    
    override func viewDidLoad() {
            super.viewDidLoad()
            dataSource = self
            if let metadataa: MetaDataResponse = loadJSON(from: "metadataResponse", as: MetaDataResponse.self) {
                self.metadataa = metadataa
                   print("✅ Metadata loaded: \(metadataa)")
               }
               
               if let bookContent: BookContent = loadJSON(from: "Token1", as: BookContent.self) {
                   self.bookContent = bookContent
                   print("✅ Book content loaded: \(bookContent)")
               }
        self.pages = self.processBookContent(
            bookContent ?? BookContent.default,
            book: bookResponse?.book ?? Book.default,
            metadata: metadataa ?? MetaDataResponse.default
        )
        if let firstVC = getViewController(at: 0) {
               setViewControllers([firstVC], direction: .forward, animated: false, completion: nil)
               print("✅ First page set")
           } else {
               print("❌ Failed to create first page")
           }
        }
        
    func loadJSON<T: Decodable>(from filename: String, as type: T.Type) -> T? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "txt") else {
            print("❌ File \(filename).json not found in bundle.")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            print("❌ Error decoding \(filename).json: \(error)")
            return nil
        }
    }

    
    func getDocumentsDirectoryPath() -> String {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].path
    }
    
    func processBookContent(_ bookContent: BookContent, book: Book, metadata: MetaDataResponse) -> [PageContent] {
        let decryptor = Decryptor()
        let decryptedText = decryptor.decryption(txt: bookContent.content, id: book.id)
        print("decryptedText Text: \(decryptedText)")
        let parsedPages = ParsePage().invoke(pageEncodedString: decryptedText, metadata: metadata, book: book)
        print("parsedPages:\(parsedPages)")
        var processedPages: [PageContent] = []
        for attributedText in parsedPages {
            processedPages.append(PageContent(attributedText: attributedText, image: nil))
        }
        return processedPages
    }

//    func splitAttributedTextIntoPages(_ attributedText: NSMutableAttributedString, maxLength: Int = 500) -> [NSMutableAttributedString] {
//           var pages: [NSMutableAttributedString] = []
//           var currentPage = NSMutableAttributedString()
//
//           attributedText.enumerateAttributes(in: NSRange(location: 0, length: attributedText.length), options: []) { attributes, range, _ in
//               let substring = attributedText.attributedSubstring(from: range)
//
//               if currentPage.length + substring.length <= maxLength {
//                   currentPage.append(substring)
//               } else {
//                   pages.append(currentPage)
//                   currentPage = NSMutableAttributedString(attributedString: substring)
//               }
//           }
//
//           if currentPage.length > 0 { pages.append(currentPage) }
//           return pages
//       }
       
//    func splitTextIntoPages(_ text: String, maxLength: Int = 500) -> [String] {
//           var pages: [String] = []
//           let words = text.components(separatedBy: " ")
//           var currentPage = ""
//
//           for word in words {
//               if (currentPage.count + word.count + 1) <= maxLength {
//                   currentPage += (currentPage.isEmpty ? "" : " ") + word
//               } else {
//                   pages.append(currentPage)
//                   currentPage = word
//               }
//           }
//           if !currentPage.isEmpty { pages.append(currentPage) }
//           return pages
//       }
    
    func getViewController(at index: Int) -> TextPageViewController? {
        guard index >= 0 && index < pages.count else { return nil }

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "TextPageViewController") as? TextPageViewController {
            vc.pageContent = pages[index]
            vc.pageIndex = index
            vc.pageController = self // ✅ Ensure proper reference
            return vc
        }
        return nil
    }
}

//func processTextWithMentions(_ attributedText: NSAttributedString) -> NSAttributedString {
//    let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)
//    let text = attributedText.string // Extract the plain text to find mentions
//    let pattern = "@(\\w+)" // Matches words starting with '@'
//    let regex = try! NSRegularExpression(pattern: pattern, options: [])
//    let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
//    for match in matches.reversed() { // Process in reverse to avoid index shift issues
//        let nsText = text as NSString
//        let matchText = nsText.substring(with: match.range)
//
//        // 🔹 Add link attribute to @word
//        let linkAttributes: [NSAttributedString.Key: Any] = [
//            .foregroundColor: UIColor.blue,
//            .underlineStyle: NSUnderlineStyle.single.rawValue,
//            .link: "navigateTo:\(matchText)" // Custom scheme for navigation
//        ]
//        let mentionString = NSAttributedString(string: matchText, attributes: linkAttributes)
//        mutableAttributedString.replaceCharacters(in: match.range, with: mentionString)
//    }
//    return mutableAttributedString
//}

//// MARK: - Text Processing Function
//func processTextWithImages(_ text: String) -> NSAttributedString {
//    let attributedString = NSMutableAttributedString(string: text)
//    let pattern = "##(.*?)##" // Regex pattern to find ##image_name##
//
//    let regex = try! NSRegularExpression(pattern: pattern, options: [])
//    let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
//    var offset = 0 // Adjust offset since replacing text changes positions
//    for match in matches {
//        let range = match.range(at: 1) // Get the image name
//        let nsText = text as NSString
//        let imageName = nsText.substring(with: range)
//
//        if let image = UIImage(named: imageName) {
//            let attachment = NSTextAttachment()
//            attachment.image = image
//            attachment.bounds = CGRect(x: 0, y: -5, width: 50, height: 50) // Adjust size
//
//            let imageString = NSAttributedString(attachment: attachment)
//            let fullMatchRange = match.range(at: 0)
//            let adjustedRange = NSRange(location: fullMatchRange.location - offset, length: fullMatchRange.length)
//
//            attributedString.replaceCharacters(in: adjustedRange, with: imageString)
//            offset += fullMatchRange.length - imageString.length
//        }
//    }
//    return attributedString
//}

extension PagedTextViewController {
    func navigateToPage(_ index: Int) {
        guard let targetVC = getViewController(at: index) else { return }
        let direction: UIPageViewController.NavigationDirection = index > currentIndex ? .forward : .reverse
        setViewControllers([targetVC], direction: direction, animated: true, completion: nil)
        currentIndex = index
        print("index : \(index)")
        pageControl.currentPage = index // ✅ Update page dots
    }

    // MARK: - PageViewController DataSource Methods
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? TextPageViewController else { return nil }
        return getViewController(at: vc.pageIndex - 1)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? TextPageViewController else { return nil }
        return getViewController(at: vc.pageIndex + 1)
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return pages.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return currentIndex
    }
    
}
extension PagedTextViewController {
    
    func fetchBooks(userID: Int, limit: Int = 6, offset: Int = 0, since: Int = 0, completion: @escaping (Result<[BookResponse], ErorrMessage>) -> Void) {
        NetworkService.shared.getResults(APICase: .fetchBooks(userID: userID, limit: limit, offset: offset, since: since), decodingModel: [BookResponse].self) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let bookResponses):
                    print("✅ Books: \(bookResponses)")
                    completion(.success(bookResponses))
                case .failure(let error):
                    print("❌ Error fetching books: \(error)")
                    completion(.failure(.InvalidRequest))
                }
            }
        }
    }

    func fetchBookMetadata(bookID: Int, completion: @escaping (Result<MetaDataResponse, ErorrMessage>) -> Void) {
        NetworkService.shared.getResults(APICase: .fetchBookMetadata(bookID: bookID), decodingModel: MetaDataResponse.self) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let metadata):
                    print("✅ Metadata: \(metadata)")

                    if let encodingData = metadata.decodedEncoding() {
                        print("✅ Decoded Encoding: \(encodingData)")
                    }

                    if let indexData = metadata.decodedIndex() {
                        print("✅ Decoded Index: \(indexData)")
                    }
                    
                    completion(.success(metadata))
                case .failure(let error):
                    print("❌ Error fetching metadata: \(error)")
                    completion(.failure(.InvalidRequest))
                }
            }
        }
    }

    func fetchFirstToken(bookID: Int, tokenID: Int, completion: @escaping (Result<BookContent, ErorrMessage>) -> Void) {
        NetworkService.shared.getResults(
            APICase: .fetchFirstToken(bookID: bookID, tokenID: tokenID),
            decodingModel: BookContent.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let bookContent):
                    print("✅ Book Content: \(bookContent)")
                    completion(.success(bookContent))
                case .failure(let error):
                    print("❌ Error fetching book content: \(error)")
                    completion(.failure(.InvalidRequest))
                }
            }
        }
    }
}
