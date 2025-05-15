//
//  PagedTextViewController.swift
//  IH_Alex
//
//  Created by esterelzek on 16/02/2025.
//

import Foundation
import UIKit
import CloudKit

// hello esther 
// hello esther
struct PageContent: Equatable {
    let attributedText: NSAttributedString
    let image: UIImage?
    let originalPageIndex: Int
    let pageNumberInChapter: Int
    let pageNumberInBook: Int
    let chapterNumber: Int
    let chunkNumber: Int
    let pageIndexInBook: Int
    let rangeInOriginal: NSRange
    let globalStartIndex: Int
    let globalEndIndex: Int

    static func == (lhs: PageContent, rhs: PageContent) -> Bool {
        return lhs.pageIndexInBook == rhs.pageIndexInBook
    }
}

struct TargetLink: Codable {
    let key: String
    let chapterNumber: Int
    let pageNumber: Int
    let index: Int
}

struct OriginalPage {
    let index: Int
    let fullAttributedText: NSAttributedString
    var chunks: [PageContent]
}


enum ScrollMode: String {
    case horizontalPaging = "horizontal"
    case verticalScrolling = "vertical"
}
protocol PagedTextViewControllerDelegate: AnyObject {
    func didUpdatePage(to index: Int)
}

class PagedTextViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, PageNavigationDelegate{
    let pageControl = UIPageControl()
    var pages: [PageContent] = []
    var currentIndex = 0
    var currentBookID: Int?
    var metadataa: MetaDataResponse?
    var chapterContent: Chapter?
    var bookResponse: BookResponse?
    var bookChapters: [Chapter] = []
    var bookInfo: Book?
    var bookState: BookState?
    var pageReference: [PageReference]?
    var originalPages: [OriginalPage] = []
    var viewControllerCache: [Int: TextPageViewController] = [:]
    var isMenu: Bool = false
    var isRotationLocked = false
    var lockedOrientation: UIInterfaceOrientation?
    var pageViewController: UIPageViewController?
    weak var pageChangeDelegate: PagedTextViewControllerDelegate?
    var searchKeyword: String?
    var onLoadCompletion: (() -> Void)?
    var scrollMode: ScrollMode = .horizontalPaging {
        didSet {
            UserDefaults.standard.set(scrollMode == .horizontalPaging ? "horizontal" : "vertical", forKey: "scrollMode")
            switchScrollMode()
        }
    }

    override func viewDidLoad() {
           super.viewDidLoad()
           loadContent()
       }
       
    func loadContent() {
        reedFiles { [weak self] in
            guard let self = self else { return }
            
            self.switchScrollMode()
            self.detectInitialOrientation()
            self.restoreRotationLock()
            
            let isScreenAlwaysOn = UserDefaults.standard.bool(forKey: "keepDisplayOn")
            UIApplication.shared.isIdleTimerDisabled = isScreenAlwaysOn
            
            // ✅ Initialize the inner `UIPageViewController`
            if self.pageViewController == nil {
                let options: [UIPageViewController.OptionsKey: Any] = [.interPageSpacing: 20]
                let pageVC = UIPageViewController(transitionStyle: .scroll,
                                                  navigationOrientation: .horizontal,
                                                  options: options)
                pageVC.dataSource = self
                pageVC.delegate = self
                self.pageViewController = pageVC
            }

            // ✅ Add the pageViewController to the view hierarchy if it's not added yet
            if !self.children.contains(self.pageViewController!) {
                self.addChild(self.pageViewController!)
                self.view.addSubview(self.pageViewController!.view)
                self.pageViewController!.view.frame = self.view.bounds
                self.pageViewController!.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                self.pageViewController!.didMove(toParent: self)
            }
            
            // ✅ Set the first page if available
            if !self.pages.isEmpty, let firstVC = self.viewControllerForPage(0) {
                self.pageViewController!.setViewControllers([firstVC], direction: .forward, animated: false, completion: nil)
                print("✅ First page loaded successfully.")
            } else {
                print("❌ Pages are empty.")
            }
            
            if self.pageChangeDelegate != nil {
                print("✅ pageChangeDelegate is set correctly!")
            } else {
                print("❌ pageChangeDelegate is nil!")
            }

            DispatchQueue.main.async {
                self.onLoadCompletion?()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let backgroundView = view.viewWithTag(999) {
            backgroundView.frame = view.bounds // Ensure it covers the full screen properly
        }
    }

    func paginate(attributedText: NSAttributedString, fontSize: CGFloat, maxSize: CGSize) -> [(text: NSAttributedString, range: NSRange)] {
        print("📐 Starting Pagination with Max Size: \(maxSize) and Font Size: \(fontSize)")
        
        let effectiveFontSize = fontSize > 0 ? fontSize : 16.0
        print("🖋️ Effective Font Size for Pagination: \(effectiveFontSize)")

        let layoutManager = NSLayoutManager()
        let textStorage = NSTextStorage(attributedString: attributedText)
        textStorage.addLayoutManager(layoutManager)

        var results: [(NSAttributedString, NSRange)] = []
        var currentLocation = 0

        // Ensure fonts are valid, or replace with a fallback font if not found
        textStorage.enumerateAttribute(.font, in: NSRange(location: 0, length: attributedText.length)) { value, range, _ in
            if let font = value as? UIFont {
                if font.pointSize == 0 {
                    print("⚠️ Font with 0 size detected, correcting...")
                    textStorage.addAttribute(.font, value: UIFont.systemFont(ofSize: effectiveFontSize), range: range)
                }
            } else {
                print("⚠️ No Font Detected at range \(range), setting default.")
                textStorage.addAttribute(.font, value: UIFont.systemFont(ofSize: effectiveFontSize), range: range)
            }
        }

        while currentLocation < layoutManager.numberOfGlyphs {
            let textContainer = NSTextContainer(size: maxSize)
            textContainer.lineFragmentPadding = 0
            layoutManager.addTextContainer(textContainer)

            layoutManager.ensureLayout(for: textContainer)

            let glyphRange = layoutManager.glyphRange(for: textContainer)
            print("📝 Glyph Range Extracted: \(glyphRange), Total Glyphs: \(layoutManager.numberOfGlyphs)")

            if glyphRange.length == 0 {
                layoutManager.removeTextContainer(at: 0)
                break
            }

            let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
            let pageText = attributedText.attributedSubstring(from: charRange)
            print("✅ Created chunk from \(charRange.location) to \(charRange.location + charRange.length)")
            
            results.append((pageText, charRange))

            currentLocation = charRange.location + charRange.length
            layoutManager.removeTextContainer(at: 0)
        }

        print("✅ Total Chunks Created: \(results.count)")
        return results
    }


    
    func processMultipleBookContents(
        contents: [Chapter],
        book: Book,
        metadata: MetaDataResponse,
        fontSize: CGFloat,
        screenSize: CGSize,
        firstChapterNumber: Int,
        lastChapterNumber: Int,
        firstPageNumber: Int,
        lastPageNumber: Int
    ) -> [OriginalPage] {
        var allOriginalPages: [OriginalPage] = []
        var runningOriginalPageIndex = 0
        var currentChapterNumber = firstChapterNumber

        // ✅ Removed this line: self.bookChapters.removeAll()

        for var mutableContent in contents {
            let chapterEnd = min(currentChapterNumber, lastChapterNumber)
            let pageStart = firstPageNumber + runningOriginalPageIndex
            let pageEnd = min(pageStart + mutableContent.count, lastPageNumber)

            // ✅ Process the chapter content into OriginalPages
            let processedPages = processBookContent(
                bookContent: &mutableContent,
                book: book,
                metadata: metadata,
                fontSize: fontSize,
                screenSize: screenSize,
                originalPageOffset: runningOriginalPageIndex,
                firstChapterNumber: currentChapterNumber,
                lastChapterNumber: chapterEnd,
                firstPageNumber: pageStart,
                lastPageNumber: pageEnd
            )

            // ✅ Append to global page list
            allOriginalPages.append(contentsOf: processedPages)

            // ✅ Update the running index
            runningOriginalPageIndex += processedPages.count

            // ✅ Append the processed chapter back to bookChapters (do not clear)
            self.bookChapters.append(mutableContent)

            // ✅ Move to the next chapter
            if currentChapterNumber < lastChapterNumber {
                currentChapterNumber += 1
            }
        }

        print("✅ All Book Chapters Processed:")
        for chapter in self.bookChapters {
            print("✅Chapter \(chapter.firstChapterNumber) - Total Pages: \(chapter.pages?.count)")
        }

        // ✅ Return all processed OriginalPages
        return allOriginalPages
    }


    func processBookContent(
        bookContent: inout Chapter,
        book: Book,
        metadata: MetaDataResponse,
        fontSize: CGFloat,
        screenSize: CGSize,
        originalPageOffset: Int,
        firstChapterNumber: Int,
        lastChapterNumber: Int,
        firstPageNumber: Int,
        lastPageNumber: Int
    ) -> [OriginalPage] {
        let decryptor = Decryptor()
        let decryptedText = decryptor.decryption(txt: bookContent.content, id: book.id)

        // 🔍 Debug: Check decrypted content
        print("✅ Decrypted Text for Chapter \(firstChapterNumber):\n\(decryptedText.prefix(500))...") // Showing first 500 chars

        let parsedPages = ParsePage().invoke(pageEncodedString: decryptedText, metadata: metadata, book: book)

        // 🔍 Debug: Parsed pages count
        print("✅ Parsed Pages Count for Chapter \(firstChapterNumber): \(parsedPages.count)")

        var originalPages: [OriginalPage] = []
        var globalPageIndex = originalPageOffset
        var chapterNumber = firstChapterNumber
        var pageNumberInBook = firstPageNumber

        var totalPagesInChapter = 0
        var chapterPages: [PageContent] = []

        // ✅ Access the chapter name from the index list
        if let indexList = metadata.decodedIndex() {
            if let matchingChapter = indexList.first(where: { $0.number == chapterNumber }) {
                bookContent.chapterName = matchingChapter.name
            }
        }

        for (localPageIndex, attributedText) in parsedPages.enumerated() {
            // 🔍 Debug: Print page content size
            print("✅ Attributed Text Size for Chapter \(chapterNumber), Page \(localPageIndex): \(attributedText.length)")
            
            let mutable = NSMutableAttributedString(attributedString: attributedText)
            mutable.addAttribute(.font, value: UIFont.systemFont(ofSize: fontSize), range: NSRange(location: 0, length: mutable.length))

            // 🔍 Debug: Check before pagination
            print("✅ Paginating Chapter \(chapterNumber), Page \(localPageIndex) - Text Length: \(mutable.length)")

            let chunksWithRanges = paginate(attributedText: mutable, fontSize: fontSize, maxSize: screenSize)
            
            // 🔍 Debug: Check chunk count
            print("✅ Chunks Found: \(chunksWithRanges.count) for Chapter \(chapterNumber), Page \(localPageIndex)")

            var chunkNumber = 0
            
            let pageChunks = chunksWithRanges.map { chunk in
                let globalEndIndex = chunk.range.location + chunk.range.length
                
                let pageContent = PageContent(
                    attributedText: chunk.text,
                    image: nil,
                    originalPageIndex: globalPageIndex,
                    pageNumberInChapter: localPageIndex,
                    pageNumberInBook: pageNumberInBook,
                    chapterNumber: chapterNumber,
                    chunkNumber: chunkNumber,
                    pageIndexInBook: globalPageIndex,
                    rangeInOriginal: chunk.range,
                    globalStartIndex: chunk.range.location,
                    globalEndIndex: globalEndIndex
                )
                
                // 🔍 Debug: Log chunk details
                print("    🔍 Chunk #\(chunkNumber): Range (\(chunk.range.location) - \(globalEndIndex)), Length: \(chunk.range.length)")
                
                chunkNumber += 1
                globalPageIndex += 1
                pageNumberInBook += 1
                totalPagesInChapter += 1
                
                print("pageContent: \(pageContent)")
                chapterPages.append(pageContent)
                
                return pageContent
            }
            
            originalPages.append(
                OriginalPage(index: globalPageIndex, fullAttributedText: mutable, chunks: pageChunks)
            )
        }
        
        print("chapterPages: \(chapterPages)")
        bookContent.pages = chapterPages
        bookContent.numberOfPages = totalPagesInChapter
        
        // 🔍 Debug: Final Chapter Summary
        if let chapterName = bookContent.chapterName {
            print("✅ Chapter \(bookContent.firstChapterNumber) - \(chapterName) Processed with \(totalPagesInChapter) Pages.")
        } else {
            print("✅ Chapter \(bookContent.firstChapterNumber) Processed with \(totalPagesInChapter) Pages.")
        }

        print("✅ Pages in Chapter \(bookContent.firstChapterNumber):")
        for (index, page) in chapterPages.enumerated() {
            print("    - Page \(index + 1) → Range: \(page.rangeInOriginal)")
        }

        return originalPages
    }
}

extension PagedTextViewController {
  
    
    func navigateToPage(index: Int) {
        guard index >= 0, index < pages.count else { return }
        guard let pageViewController = pageViewController else {
            print("🚨 pageViewController is nil! Cannot navigate.")
            return
        }

        if let targetVC = getViewController(at: index){
                let direction: UIPageViewController.NavigationDirection = (index > currentIndex) ? .forward : .reverse
                setViewControllers([targetVC], direction: direction, animated: true, completion: { finished in
                    if finished {
                        self.currentIndex = index
                    }
                })
            }
      }
    func getViewController(at index: Int) -> TextPageViewController? {
        guard index >= 0 && index < pages.count else { return nil }
        viewControllerCache[index] = nil  // ✅ force clear old one
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "TextPageViewController") as? TextPageViewController else {
            return nil
        }
       
        vc.pageNavigationDelegate = self
        vc.originalPages = self.originalPages
        vc.pages = self.pages
        vc.pageContent = pages[index]
        vc.pageIndex = index
        vc.pageController = self
  //      print("current index in text vc  : \(vc.pageIndex)")
        vc.searchKeyword = self.searchKeyword
        let savedFontSize = UserDefaults.standard.float(forKey: "globalFontSize")
        if savedFontSize > 0 {
            vc.applyFontSize(CGFloat(savedFontSize))
        }
        vc.isRotationLocked = isRotationLocked
        vc.lockedOrientation = lockedOrientation
        viewControllerCache[index] = vc  // ✅ cache the fresh one
        return vc
    }
   
    func viewControllerForPage(_ pageIndex: Int) -> TextPageViewController? {
        guard pageIndex >= 0 && pageIndex < pages.count else { return nil }
        let vc = TextPageViewController()
        vc.pageContent = pages[pageIndex]
        vc.pages = self.pages
        vc.pageIndex = pageIndex
        return vc
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
        return 0
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return currentIndex
    }
    
    func getCurrentPageIndex() -> Int {
        return currentIndex
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            willTransitionTo pendingViewControllers: [UIViewController]) {
        for vc in pendingViewControllers {
            if let textVC = vc as? TextPageViewController {
                textVC.refreshContent()
                textVC.closeMenu()
                textVC.closeNote()// Prepare content before it appears
                textVC.pages = self.pages
            }
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        guard completed,
              let visibleVC = pageViewController.viewControllers?.first as? TextPageViewController
        else { return }

        DispatchQueue.main.async {
            self.currentIndex = visibleVC.pageIndex
            self.pageControl.currentPage = self.currentIndex
         //   print("self.currentIndex: \(self.currentIndex)")
            self.pageChangeDelegate?.didUpdatePage(to: self.currentIndex)
        }
    }
}


extension PagedTextViewController {
    
    func reedFiles(completion: @escaping () -> Void) {
        // ✅ Create a Dispatch Group
        let dispatchGroup = DispatchGroup()
        
        // ✅ Load Book Info
        dispatchGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            if let bookInfo: BookResponse = self.loadJSON(from: "Bookinfo", as: BookResponse.self) {
                self.bookResponse = bookInfo
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
                print("✅ Metadata loaded.")
                
                guard let metadata = self.metadataa else {
                    print("❌ Metadata not found.")
                    dispatchGroup.leave()
                    return
                }
                
                // ✅ Decode Target Links
                if let targetLinksData = metadata.targetLinks.data(using: .utf8) {
                    do {
                        let targetLinks = try JSONDecoder().decode([TargetLink].self, from: targetLinksData)
                        print("✅ Decoded Target Links: \(targetLinks)")
                        
                        // 🔹 Convert to PageReference
                        let pageReferences = targetLinks.map { link in
                            PageReference(
                                key: link.key,
                                chapterNumber: link.chapterNumber,
                                pageNumber: link.pageNumber,
                                index: link.index
                            )
                        }
                        self.pageReference = pageReferences
                        
                        // ✅ Save to UserDefaults
                        if let encoded = try? JSONEncoder().encode(pageReferences) {
                            UserDefaults.standard.set(encoded, forKey: "PageReferencesKey")
                            print("✅ PageReferences saved to UserDefaults.")
                        }
                        
                    } catch {
                        print("❌ Failed to decode targetLinks: \(error.localizedDescription)")
                    }
                } else {
                    print("❌ Failed to convert targetLinks string to Data.")
                }
            }
            dispatchGroup.leave()
        }
        
        // ✅ Load Chapters and Process Pages
        dispatchGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            self.bookChapters.removeAll()
            let tokens = ["Tooken1", "Tooken2", "Tooken3", "Tooken4", "Tooken5", "Tooken6", "Tooken7"]
            
            var allOriginalPages: [OriginalPage] = []
            
            for token in tokens {
                if var bookContent: Chapter = self.loadJSON(from: token, as: Chapter.self) {
                    // After loading raw JSON, process pages for this chapter:
                    let fontSize = CGFloat(UserDefaults.standard.float(forKey: "globalFontSize"))
                    let screenSize = UIScreen.main.bounds.inset(by: UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)).size
                    
                    let originalPages = self.processMultipleBookContents(
                        contents: [bookContent],
                        book: self.bookResponse?.book ?? Book.default,
                        metadata: self.metadataa ?? MetaDataResponse.default,
                        fontSize: fontSize,
                        screenSize: screenSize,
                        firstChapterNumber: bookContent.firstChapterNumber,
                        lastChapterNumber: bookContent.lastChapterNumber,
                        firstPageNumber: bookContent.firstPageNumber,
                        lastPageNumber: bookContent.lastPageNumber
                    )
                    
                    allOriginalPages.append(contentsOf: originalPages)
                    
                    // Combine all chunks from originalPages into chapter pages
                    let chapterPages = originalPages.flatMap { $0.chunks }
                    
                    // Assign pages and page count back to the chapter instance
                    bookContent.pages = chapterPages
                    bookContent.numberOfPages = chapterPages.count
                    
                    self.bookChapters.append(bookContent)
                    
                    print("✅ Loaded and processed chapter \(bookContent.id) with \(chapterPages.count) pages.")
                } else {
                    print("❌ Failed to load \(token)")
                }
            }
            
            // ✅ Here we initialize `pages` with all chunks from `allOriginalPages`
            self.pages = allOriginalPages.flatMap { $0.chunks }
            print("✅ Total Pages Available: \(self.pages.count)")
            
            dispatchGroup.leave()
        }
        
        // ✅ Completion Handler: Called when all async tasks are done
        dispatchGroup.notify(queue: .main) {
            print("✅ All files loaded successfully!")
            completion() // 🔸 Call the completion when everything is ready
        }
    }
}

extension PagedTextViewController {
    func goToPage(index: Int) {
        guard index >= 0, index < pages.count else {
            print("❌ Invalid page index: \(index)")
            return
        }
        
        let direction: UIPageViewController.NavigationDirection = (index >= currentIndex) ? .forward : .reverse
        
        let newVC = TextPageViewController()
        newVC.pages = pages
        newVC.originalPages = originalPages
        newVC.pageContent = pages[index]
        newVC.pageIndex = index
        newVC.pageController = self
        newVC.pageNavigationDelegate = self
        
        setViewControllers([newVC], direction: direction, animated: true) { completed in
            if completed {
                self.currentIndex = index
            }
        }
    }
    func currentTextPageViewController() -> TextPageViewController? {
        guard let pageVC = pageViewController else {
            print("❌ pageViewController is nil.")
            return nil
        }
        
        guard let firstVC = pageVC.viewControllers?.first as? TextPageViewController else {
            print("❌ No TextPageViewController found in viewControllers.")
            return nil
        }
        
        print("✅ Found active TextPageViewController.")
        return firstVC
    }

    func clearAdjacentViewControllerCache() {
        viewControllerCache[currentIndex - 1] = nil
        viewControllerCache[currentIndex] = nil
        viewControllerCache[currentIndex + 1] = nil
        
    }

    func recreateViewController(at index: Int) -> TextPageViewController? {
        guard index >= 0 && index < pages.count else { return nil }
        let vc = TextPageViewController()
        vc.originalPages = self.originalPages
        vc.pages = self.pages
        vc.pageContent = pages[index]
        vc.pageIndex = index
        vc.reloadPageContent()
        vc.applySavedAppearance()
        vc.refreshContent()
        viewControllerCache[index] = vc  // ✅ cache it
        return vc
    }

    func updatePageControl() {
        pageControl.numberOfPages = self.pages.count
           pageControl.currentPage = currentIndex
       }
    
    func clearViewControllerCache(for indexes: [Int]) {
        for index in indexes {
            viewControllerCache[index] = nil
        }
    }
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

    func fetchFirstToken(bookID: Int, tokenID: Int, completion: @escaping (Result<Chapter, ErorrMessage>) -> Void) {
        NetworkService.shared.getResults(
            APICase: .fetchFirstToken(bookID: bookID, tokenID: tokenID),
            decodingModel: Chapter.self
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
    private func mapToBookState(bookResponse: BookResponse, metadata: MetaDataResponse, bookContent: Chapter) -> BookState {
           let book = bookResponse.book
           let coverData = "loadCoverImage(named: book.cover)" // Convert cover image if needed
           
           return BookState(
               bookId: book.id,
               bookName: book.name,
               pagesNumber: book.pagesNumber,
               chaptersNumber: book.chaptersNumber,
               description: book.description,
               cover: coverData,
               bookSize: Float(book.size),
               readingProgress: book.readingProgress,
               chapters: extractChapters(from: bookContent), // Extract chapters from content
               bookMetadata: BookMetadata(
                   lastUpdated: book.lastUpdated,
                   isDeleted: book.isDeleted
               ),
               subscriptionId: book.subscriptionID,
               summary: book.summary,
               bookRating: book.bookRating.map { Double($0) },
               releaseDate: book.releaseDate,
               publisherName: bookResponse.publisher.first?.name,
               internationalNum: book.international_num,
               language: book.language,
               categories: bookResponse.categories,
               authorsName: bookResponse.author.map { $0.name },
               tags: bookResponse.tags,
               translatorsName: bookResponse.translators.map { $0.name },
               bookHighlights: [], // Load if highlights exist
               bookBookmarks: [], // Load bookmarks from local storage if needed
               bookNotes: [] // Load notes from local storage if needed
           )
       }
       private func extractChapters(from bookContent: Chapter) -> [ChapterData] {
           return [
               ChapterData(
                   chapterNumber: bookContent.firstChapterNumber,
                   title: "Chapter \(bookContent.firstChapterNumber)",
                   content: bookContent.content
               )
           ]
       }
}
extension PagedTextViewController {
    func applyFontSizeToAllPages(_ fontSize: CGFloat) {
           self.viewControllers?.forEach { vc in
               if let textVC = vc as? TextPageViewController {
                   textVC.applyFontSize(fontSize)
               }
           }
       }
    
    func applyBackgroundAndFontColorToAllPages(background: UIColor, font: UIColor) {
        self.viewControllers?.forEach { vc in
            if let textVC = vc as? TextPageViewController {
                textVC.applyAppearanceAttributes(fontColor: font, backgroundColor: background)
            }
        }
        
        for index in 0..<pages.count {
            if let textVC = getViewController(at: index) {
                textVC.applyAppearanceAttributes(fontColor: font, backgroundColor: background)
            }
        }
    }
    
    func applyLineSpacingToAllPages(_ lineSpacing: CGFloat) {
           self.viewControllers?.forEach { vc in
               if let textVC = vc as? TextPageViewController {
                   textVC.applyLineSpacing(lineSpacing)
               }
           }
       }
        func rotateScreen() {
            toggleRotationLock()
        }
}
extension PagedTextViewController {
    private func switchScrollMode() {
        self.view.subviews.forEach { $0.removeFromSuperview() }
        self.view.backgroundColor = .white
        let newOrientation: UIPageViewController.NavigationOrientation = (scrollMode == .horizontalPaging) ? .horizontal : .vertical
        let newPageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: newOrientation,
            options: nil
        )
        
        newPageViewController.dataSource = self
        newPageViewController.delegate = self
        self.addChild(newPageViewController)
        self.view.addSubview(newPageViewController.view)
        newPageViewController.didMove(toParent: self)

        if let firstVC = getViewController(at: currentIndex) {
            newPageViewController.setViewControllers([firstVC], direction: .forward, animated: false, completion: nil)
        }

        self.willMove(toParent: nil)
        self.view.subviews.forEach { $0.removeFromSuperview() }
        self.removeFromParent()
        self.view.addSubview(newPageViewController.view)
        self.addChild(newPageViewController)
        newPageViewController.didMove(toParent: self)
    }

       func detectInitialOrientation() {
           guard let windowScene = view.window?.windowScene else { return }
           let currentOrientation = windowScene.interfaceOrientation
           lockedOrientation = currentOrientation
           print("📌 Initial Orientation Detected: \(currentOrientation.rawValue)")
       }

    func toggleRotationLock() {
        guard let windowScene = view.window?.windowScene else {
            print("❌ No window scene found.")
            return
        }

        let currentOrientation = windowScene.interfaceOrientation
        print("📌 Current Orientation: \(currentOrientation.rawValue)")

        if isRotationLocked {
            isRotationLocked = false
            lockedOrientation = nil
            print("🔄 Rotation Unlocked: Now follows device movement")
            UserDefaults.standard.set(false, forKey: "rotationLocked")
            UserDefaults.standard.removeObject(forKey: "lockedOrientation")
            let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .all)
            do {
                try windowScene.requestGeometryUpdate(geometryPreferences)
                print("✅ Successfully Unlocked Rotation")
            } catch {
                print("❌ Error unlocking rotation: \(error)")
            }
        } else {
            isRotationLocked = true
            lockedOrientation = currentOrientation
            print("🔒 Rotation Locked to: \(currentOrientation.rawValue)")
            UserDefaults.standard.set(true, forKey: "rotationLocked")
            UserDefaults.standard.set(currentOrientation.rawValue, forKey: "lockedOrientation")
            let orientationMask: UIInterfaceOrientationMask = {
                switch currentOrientation {
                case .portrait: return .portrait
                case .portraitUpsideDown: return .portraitUpsideDown
                case .landscapeLeft: return .landscapeLeft
                case .landscapeRight: return .landscapeRight
                default: return .all
                }
            }()
            let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: orientationMask)
            do {
                try windowScene.requestGeometryUpdate(geometryPreferences)
                print("✅ Successfully Locked Rotation to \(currentOrientation.rawValue)")
            } catch {
                print("❌ Error locking rotation: \(error)")
            }
        }
        UserDefaults.standard.synchronize()
        self.setNeedsUpdateOfSupportedInterfaceOrientations()
    }

    func restoreRotationLock() {
        let savedRotationLock = UserDefaults.standard.bool(forKey: "rotationLocked")
        let savedOrientationRaw = UserDefaults.standard.integer(forKey: "lockedOrientation")
        isRotationLocked = savedRotationLock
        if savedRotationLock {
            lockedOrientation = UIInterfaceOrientation(rawValue: savedOrientationRaw)
            print("🔒 Restored Rotation Lock: \(lockedOrientation?.rawValue ?? -1)")
        } else {
            lockedOrientation = nil
        }
        print("📌 Rotation Lock Restored: \(isRotationLocked), Locked Orientation: \(lockedOrientation?.rawValue ?? -1)")
    }
       override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
           if isRotationLocked, let lockedOrientation = lockedOrientation {
               print("🔒 Enforcing Locked Orientation: \(lockedOrientation.rawValue)")
               switch lockedOrientation {
               case .portrait: return .portrait
               case .portraitUpsideDown: return .portraitUpsideDown
               case .landscapeLeft: return .landscapeLeft
               case .landscapeRight: return .landscapeRight
               default: return .all
               }
           }
           return .all
       }
       override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
           super.viewWillTransition(to: size, with: coordinator)

           guard let windowScene = view.window?.windowScene else {
               print("❌ No window scene found.")
               return
           }
           let newOrientation = windowScene.interfaceOrientation
           print("🔄 Detected Rotation: New Orientation = \(newOrientation.rawValue)")
           if isRotationLocked, let lockedOrientation = lockedOrientation {
               print("🔒 Rotation is LOCKED to: \(lockedOrientation.rawValue)")
           } else {
               print("🔄 Rotation is UNLOCKED: Device can rotate freely.")
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
    
    func refreshAllPages() {
        print("🔄 Refreshing all pages")
        for (index, viewController) in viewControllerCache {
            print("🔄 Refreshing page at index: \(index)")
            viewController.applySavedAppearance()
            viewController.reloadPageContent()
        }
    }
    func rebuildPages(fontSize: CGFloat, screenSize: CGSize) {
            // Clear existing pages and cache
            pages.removeAll()
            viewControllerCache.removeAll()
            originalPages.removeAll()

            var globalStartIndex = 0
            var globalPageIndex = 0

            // ✅ Loop through each chapter in the book using its index
            for (index, _) in bookChapters.enumerated() {
                var chapter = bookChapters[index]  // ➡️ Make a mutable copy

                let firstChapterNumber = chapter.firstChapterNumber
                let firstPageNumber = chapter.firstPageNumber

                // ✅ Decrypt the content
                let decryptor = Decryptor()
                let decryptedText = decryptor.decryption(txt: chapter.content, id: bookResponse?.book.id ?? 0)

                // ✅ Parse the pages
                let parsedPages = ParsePage().invoke(
                    pageEncodedString: decryptedText,
                    metadata: metadataa ?? MetaDataResponse.default,
                    book: bookResponse?.book ?? Book.default
                )

                var chapterNumber = firstChapterNumber
                var pageNumberInBook = firstPageNumber
                var chapterPages: [PageContent] = []
                var totalPagesInChapter = 0

                // ✅ Loop through parsed pages
                for (localPageIndex, attributedText) in parsedPages.enumerated() {
                    // ✅ Set font attributes
                    let mutable = NSMutableAttributedString(attributedString: attributedText)
                    mutable.addAttribute(.font, value: UIFont.systemFont(ofSize: fontSize), range: NSRange(location: 0, length: mutable.length))

                    // ✅ Paginate the content based on the screen size
                    let chunksWithRanges = paginate(attributedText: mutable, fontSize: fontSize, maxSize: screenSize)
                    var chunkNumber = 0

                    // ✅ Create `PageContent` for each chunk
                    let pageChunks = chunksWithRanges.map { chunk in
                        let globalEndIndex = globalStartIndex + chunk.text.length

                        let pageContent = PageContent(
                            attributedText: chunk.text,
                            image: nil,
                            originalPageIndex: globalPageIndex,
                            pageNumberInChapter: localPageIndex + 1,
                            pageNumberInBook: pageNumberInBook,
                            chapterNumber: chapterNumber,
                            chunkNumber: chunkNumber,
                            pageIndexInBook: globalPageIndex,
                            rangeInOriginal: chunk.range,
                            globalStartIndex: globalStartIndex,
                            globalEndIndex: globalEndIndex
                        )

                        // ✅ Collect chapter pages
                        chapterPages.append(pageContent)

                        globalStartIndex = globalEndIndex
                        chunkNumber += 1
                        globalPageIndex += 1
                        pageNumberInBook += 1
                        totalPagesInChapter += 1

                        return pageContent
                    }

                    // ✅ Create OriginalPage and append to the list
                    let originalPage = OriginalPage(index: globalPageIndex, fullAttributedText: mutable, chunks: pageChunks)
                    self.originalPages.append(originalPage)
                    self.pages.append(contentsOf: pageChunks)
                }

                // ✅ Attach the chapter pages and page count back to the Chapter instance
                chapter.pages = chapterPages
                chapter.numberOfPages = totalPagesInChapter

                // ✅ Set the chapter name if available
                if let chapterMetadata = metadataa?.decodedIndex()?.first(where: { $0.number == chapterNumber }) {
                    chapter.chapterName = chapterMetadata.name
                }

                // ✅ Reassign the updated chapter back into the array
                bookChapters[index] = chapter

                // ✅ Log the results for verification
                print("✅ Chapter \(chapter.firstChapterNumber) Processed with \(totalPagesInChapter) Pages.")
                print("✅ Pages in Chapter \(chapter.firstChapterNumber):")
                for (index, page) in chapterPages.enumerated() {
                    print("    - Page \(index + 1) → Range: \(page.rangeInOriginal)")
                }
            }

            // ✅ Clear the cache and refresh the UI
            clearAdjacentViewControllerCache()
            DispatchQueue.main.async {
                guard self.pages.indices.contains(self.currentIndex) else { return }
                if let refreshedVC = self.recreateViewController(at: self.currentIndex) {
                    self.setViewControllers([refreshedVC], direction: .forward, animated: false, completion: nil)
                }
                self.updatePageControl()
            }
       }

}
