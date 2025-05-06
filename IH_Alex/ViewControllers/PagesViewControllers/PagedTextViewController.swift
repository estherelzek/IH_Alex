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

class PagedTextViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate{
    let pageControl = UIPageControl()
    var pages: [PageContent] = []
    var currentIndex = 0
    var currentBookID: Int?
    var metadataa: MetaDataResponse?
    var bookContent: BookContent?
    var bookResponse: BookResponse?
    var bookContents: [BookContent] = []
    var bookInfo: Book?
    var bookState: BookState?
    var pageReference: [PageReference]?
    var originalPages: [OriginalPage] = []
    var viewControllerCache: [Int: TextPageViewController] = [:]
    var isMenu: Bool = false
    var isRotationLocked = false
    var lockedOrientation: UIInterfaceOrientation?
    var pageViewController: UIPageViewController!
    weak var pageChangeDelegate: PagedTextViewControllerDelegate?

    var scrollMode: ScrollMode = .horizontalPaging {
        didSet {
            UserDefaults.standard.set(scrollMode == .horizontalPaging ? "horizontal" : "vertical", forKey: "scrollMode")
            switchScrollMode()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let savedModeString = UserDefaults.standard.string(forKey: "savedScrollMode"),
              let savedMode = ScrollMode(rawValue: savedModeString) {
               scrollMode = savedMode
           } else {
               scrollMode = .horizontalPaging // Default mode
           }
       
        dataSource = self
        reedFiles()
        switchScrollMode()
        detectInitialOrientation()
        restoreRotationLock()
        let isScreenAlwaysOn = UserDefaults.standard.bool(forKey: "keepDisplayOn")
        UIApplication.shared.isIdleTimerDisabled = isScreenAlwaysOn
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController.dataSource = self
        pageViewController.delegate = self
            addChild(pageViewController)
            view.addSubview(pageViewController.view)
            pageViewController.didMove(toParent: self)
            if let firstVC = viewControllerForPage(0) {
                pageViewController.setViewControllers([firstVC], direction: .forward, animated: false, completion: nil)
            }
        self.view.backgroundColor = .red
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
    
    func refreshAllPages() {
        print("🔄 Refreshing all pages")
        for (index, viewController) in viewControllerCache {
            print("🔄 Refreshing page at index: \(index)")
            viewController.applySavedAppearance()  
            viewController.reloadPageContent()
        }
    }

    func paginate(attributedText: NSAttributedString, fontSize: CGFloat, maxSize: CGSize) -> [(text: NSAttributedString, range: NSRange)] {
           let layoutManager = NSLayoutManager()
           let textStorage = NSTextStorage(attributedString: attributedText)
           textStorage.addLayoutManager(layoutManager)

           var results: [(NSAttributedString, NSRange)] = []
           var currentLocation = 0

           while currentLocation < layoutManager.numberOfGlyphs {
               let textContainer = NSTextContainer(size: maxSize)
               textContainer.lineFragmentPadding = 0
               layoutManager.addTextContainer(textContainer)

               let glyphRange = layoutManager.glyphRange(for: textContainer)
               if glyphRange.length == 0 { break }

               let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
               let pageText = attributedText.attributedSubstring(from: charRange)
               results.append((pageText, charRange))

               currentLocation = charRange.location + charRange.length
           }

           return results
       }
    
    func rebuildPages(fontSize: CGFloat, screenSize: CGSize) {
        pages.removeAll()
        viewControllerCache.removeAll()

        var pageNumberInBook = 0
        let chapterNumber = 0  // This would depend on the chapter logic you have, if any
        var globalStartIndex = 0  // This will keep track of the cumulative global start index across pages

        for original in originalPages {
            let updatedAttributed = NSMutableAttributedString(attributedString: original.fullAttributedText)
            updatedAttributed.addAttribute(.font, value: UIFont.systemFont(ofSize: fontSize), range: NSRange(location: 0, length: updatedAttributed.length))

            let chunksWithRanges = paginate(attributedText: updatedAttributed, fontSize: fontSize, maxSize: screenSize)

            for chunk in chunksWithRanges {
                let globalEndIndex = globalStartIndex + chunk.text.length

                let pageContent = PageContent(
                    attributedText: chunk.text,
                    image: nil,
                    originalPageIndex: original.index,
                    pageNumberInChapter: original.index, // Assuming the chapter number logic is based on originalIndex or something else
                    pageNumberInBook: original.index,
                    chapterNumber: original.chunks.count, // This could be dynamic if you have chapters
                    chunkNumber: pageNumberInBook, // This could be a separate counter per chunk
                    pageIndexInBook: pageNumberInBook,
                    rangeInOriginal: chunk.range,
                    globalStartIndex: globalStartIndex,
                    globalEndIndex: globalEndIndex
                )
        
                pages.append(pageContent)
               pageNumberInBook += 1
                globalStartIndex = globalEndIndex
              //  print(" pageNumberInBook: \(pageNumberInBook)")
            }
        }

        // 🔍 Find new page index by preserved snippet
        if let preservedTextSnippet = UserDefaults.standard.string(forKey: "preservedTextSnippet") {
            for (index, page) in pages.enumerated() {
                let pageText = page.attributedText.string
                if pageText.contains(preservedTextSnippet) {
                    currentIndex = index
                    print("📍 Found preserved snippet in page \(index)")
                    break
                }
            }
        } else {
            currentIndex = 0
        }

        clearAdjacentViewControllerCache()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let refreshedVC = self.recreateViewController(at: self.currentIndex) {
                self.setViewControllers([refreshedVC], direction: .forward, animated: false, completion: nil)
            }
            self.updatePageControl()
        }
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

    func processMultipleBookContents(
        _ contents: [BookContent],
        book: Book,
        metadata: MetaDataResponse,
        fontSize: CGFloat,
        screenSize: CGSize
    ) -> [OriginalPage] {
        var allOriginalPages: [OriginalPage] = []
        var runningOriginalPageIndex = 0

        for content in contents {
            let processed = processBookContent(
                content,
                book: book,
                metadata: metadata,
                fontSize: fontSize,
                screenSize: screenSize,
                originalPageOffset: runningOriginalPageIndex
            )

            allOriginalPages.append(contentsOf: processed)
            runningOriginalPageIndex += processed.count
        }
        return allOriginalPages
    }
    
    func processBookContent(
        _ bookContent: BookContent,
        book: Book,
        metadata: MetaDataResponse,
        fontSize: CGFloat,
        screenSize: CGSize,
        originalPageOffset: Int
    ) -> [OriginalPage] {
        let decryptor = Decryptor()
        let decryptedText = decryptor.decryption(txt: bookContent.content, id: book.id)
        let parsedPages = ParsePage().invoke(pageEncodedString: decryptedText, metadata: metadata, book: book)

        var originalPages: [OriginalPage] = []
        var globalPageIndex = originalPageOffset  // Start from the offset passed from the previous token

        for (localPageIndex, attributedText) in parsedPages.enumerated() {
            let mutable = NSMutableAttributedString(attributedString: attributedText)
            mutable.addAttribute(.font, value: UIFont.systemFont(ofSize: fontSize), range: NSRange(location: 0, length: mutable.length))
            let chunksWithRanges = paginate(attributedText: mutable, fontSize: fontSize, maxSize: screenSize)
            var chunkNumber = 0
            let pageChunks = chunksWithRanges.map { chunk in
                let globalEndIndex = chunk.range.location + chunk.range.length

                let pageContent = PageContent(
                    attributedText: chunk.text,
                    image: nil,
                    originalPageIndex: globalPageIndex,  // This should now represent the actual "global" original page
                    pageNumberInChapter: localPageIndex,
                    pageNumberInBook: globalPageIndex + 1,  // Ensure this is globally incremented
                    chapterNumber: bookContent.count, // Use the correct chapter if available
                    chunkNumber: chunkNumber,
                    pageIndexInBook: globalPageIndex,
                    rangeInOriginal: chunk.range,
                    globalStartIndex: chunk.range.location,
                    globalEndIndex: globalEndIndex
                )
                chunkNumber += 1
                globalPageIndex += 1  // Increase the global page index for the next chunk
                return pageContent
            }
            originalPages.append(
                OriginalPage(index: globalPageIndex, fullAttributedText: mutable, chunks: pageChunks)
            )
        }

        return originalPages
    }
    func navigateToPage(index: Int) {
        guard index >= 0, index < pages.count else { return }
        guard let pageViewController = pageViewController else {
            print("🚨 pageViewController is nil! Cannot navigate.")
            return
        }
        print("navigateToPage: \(index)")

        if let targetVC = getViewController(at: index){
                let direction: UIPageViewController.NavigationDirection = (index > currentIndex) ? .forward : .reverse
                
                // Use `self` directly for setViewControllers
                setViewControllers([targetVC], direction: direction, animated: true, completion: { finished in
                    if finished {
                        self.currentIndex = index
                    }
                })
            }
    }
    
}

extension PagedTextViewController {
  

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
        print("current index in text vc  : \(vc.pageIndex)")
  
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
            print("self.currentIndex: \(self.currentIndex)")
            self.pageChangeDelegate?.didUpdatePage(to: self.currentIndex)
        }
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
            // 🔒 Lock rotation to the current orientation
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
       // ✅ Ensure Locked Rotation is Respected
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
       // ✅ Detect when device rotates
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
    private func mapToBookState(bookResponse: BookResponse, metadata: MetaDataResponse, bookContent: BookContent) -> BookState {
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
       private func extractChapters(from bookContent: BookContent) -> [Chapter] {
           return [
               Chapter(
                   chapterNumber: bookContent.firstChapterNumber,
                   title: "Chapter \(bookContent.firstChapterNumber)",
                   content: bookContent.content
               )
           ]
       }
    func reedFiles() {
        // ✅ Load Book Info
        if let bookInfo: BookResponse = loadJSON(from: "Bookinfo", as: BookResponse.self) {
            self.bookResponse = bookInfo
        }

        // ✅ Load Metadata
        if let metadataa: MetaDataResponse = loadJSON(from: "metadataResponse", as: MetaDataResponse.self) {
            self.metadataa = metadataa
        }
        
        if let pageReferences: [PageReference] = loadJSON(from: "PageReference", as: [PageReference].self) {
            self.pageReference = pageReferences

            // ✅ Save to UserDefaults
            if let encoded = try? JSONEncoder().encode(pageReferences) {
                UserDefaults.standard.set(encoded, forKey: "PageReferencesKey")
            }
        }


        print(" self.pageReference : \( self.pageReference)")
        // ✅ Load Book Contents
        bookContents.removeAll()
        let tokens = ["Tooken1", "Tooken2", "Tooken3", "Tooken4", "Tooken5", "Tooken6", "Tooken7"]
        for token in tokens {
            if let bookContent: BookContent = loadJSON(from: token, as: BookContent.self) {
                bookContents.append(bookContent)
            } else {
                print("❌ Failed to load \(token)")
            }
        }

        guard !bookContents.isEmpty else {
            print("❌ No book content loaded.")
            return
        }

        // ✅ Get screen and font size
        let fontSize = CGFloat(UserDefaults.standard.float(forKey: "globalFontSize"))
        let screenSize = UIScreen.main.bounds.inset(by: UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)).size

        // ✅ Save the current page index before reload
        let currentIndex = (viewControllers?.first as? TextPageViewController)?.pageIndex ?? 0

        // ✅ Clear cached view controllers if using a cache
        viewControllerCache.removeAll()

        // ✅ Re-process content and regenerate pages
        let originalPages = self.processMultipleBookContents(
            bookContents,
            book: bookResponse?.book ?? Book.default,
            metadata: metadataa ?? MetaDataResponse.default,
            fontSize: fontSize,
            screenSize: screenSize
        )

        self.originalPages = originalPages
        print("")
        self.pages = originalPages.flatMap { $0.chunks }

        // ✅ Merge content and update book state
        let mergedContent = bookContents.reduce(BookContent.default) { $0.merge(with: $1) }

        if let bookInfo = bookResponse {
            self.bookState = mapToBookState(
                bookResponse: bookInfo,
                metadata: metadataa ?? MetaDataResponse.default,
                bookContent: mergedContent
            )
        }

        // ✅ Forcefully reload the current page with new instance
        DispatchQueue.main.async {
            guard self.pages.indices.contains(currentIndex) else { return }

            if let current = self.getViewController(at: currentIndex),
               let tempNext = self.getViewController(at: currentIndex + 1),
               let tempprev = self.getViewController(at: currentIndex - 1)
            {
                // Briefly flip forward and then back to force UIPageViewController to refresh neighbors
                self.setViewControllers([tempNext], direction: .forward, animated: false) { _ in
                    self.setViewControllers([current], direction: .reverse, animated: false, completion: nil)
                }
            } else if let current = self.getViewController(at: currentIndex) {
                self.setViewControllers([current], direction: .forward, animated: false, completion: nil)
            }
        }
    }

}
extension PagedTextViewController: PageNavigationDelegate {
//    func navigateToPage(index: Int) {
//        navigateToPage(index) // 🛠 call your normal navigation function
//    }
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
        return pageViewController?.viewControllers?.first as? TextPageViewController
    }

}
