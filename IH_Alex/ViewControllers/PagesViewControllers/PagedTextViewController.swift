//
//  PagedTextViewController.swift
//  IH_Alex
//
//  Created by esterelzek on 16/02/2025.
//
import Foundation
import UIKit
import CloudKit

struct ChapterPages: Equatable {
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

    static func == (lhs: ChapterPages, rhs: ChapterPages) -> Bool {
        return lhs.pageIndexInBook == rhs.pageIndexInBook
    }
}

struct TargetLink: Codable {
    let key: String
    let chapterNumber: Int
    let pageNumber: Int
    let index: Int
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
    var currentIndex = 0
    var currentBookID: Int?
    var metadataa: MetaDataResponse?
    var bookResponse: BookResponse?
    var bookInfo: Book?
    var bookState: BookState?
    var pageReference: [PageReference]?
    var viewControllerCache: [Int: TextPageViewController] = [:]
    var isMenu: Bool = false
    var isRotationLocked = false
    var lockedOrientation: UIInterfaceOrientation?
    var pageViewController: UIPageViewController?
    weak var pageChangeDelegate: PagedTextViewControllerDelegate?
    var searchKeyword: String?
    var onLoadCompletion: (() -> Void)?
    var bookChapterrs: [Chapterr] = []
    var pagess: [Page] = []
    var chunkedPages: [Chunk] = []  // This is rebuilt every time
    var scrollMode: ScrollMode = .verticalScrolling {
        didSet {
            UserDefaults.standard.set(scrollMode == .verticalScrolling ? "vertical" : "horizontal", forKey: "scrollMode")
            switchScrollMode()
        }
    }

    override func viewDidLoad() {
           super.viewDidLoad()
           loadContent()
       }
       
    func loadContent() {
        loadRawChapters { [weak self] in
            guard let self = self else { return }
         
            self.switchScrollMode()
            self.detectInitialOrientation()
            self.restoreRotationLock()

            let isScreenAlwaysOn = UserDefaults.standard.bool(forKey: "keepDisplayOn")
            UIApplication.shared.isIdleTimerDisabled = isScreenAlwaysOn

            if self.pageViewController == nil {
                let options: [UIPageViewController.OptionsKey: Any] = [.interPageSpacing: 0]
                let pageVC = UIPageViewController(transitionStyle: .scroll,
                                                  navigationOrientation: .horizontal,
                                                  options: options)
                pageVC.dataSource = self
                pageVC.delegate = self
                self.pageViewController = pageVC
            }

            if !self.children.contains(self.pageViewController!) {
                self.addChild(self.pageViewController!)
                self.view.addSubview(self.pageViewController!.view)
                self.pageViewController!.view.frame = self.view.bounds
                self.pageViewController!.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                self.pageViewController!.didMove(toParent: self)
            }

            if !self.pagess.isEmpty, let firstVC = self.viewControllerForPage(0) {
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
    //    print("📐 Starting Pagination with Max Size: \(maxSize) and Font Size: \(fontSize)")
        
        let effectiveFontSize = fontSize > 0 ? fontSize : 16.0
    //    print("🖋️ Effective Font Size for Pagination: \(effectiveFontSize)")
       
        let fullText = NSMutableAttributedString(attributedString: attributedText)
        fullText.enumerateAttribute(.font, in: NSRange(location: 0, length: fullText.length)) { value, range, _ in
            if let existingFont = value as? UIFont {
                fullText.addAttribute(.font, value: existingFont.withSize(effectiveFontSize), range: range)
            } else {
                fullText.addAttribute(.font, value: UIFont.systemFont(ofSize: effectiveFontSize), range: range)
            }
        }
        
        var results: [(NSAttributedString, NSRange)] = []
        var currentLocation = 0
        var iterationCount = 0
        let fullLength = fullText.length
        
        while currentLocation < fullLength {
            iterationCount += 1
            if iterationCount > 10000 {
                print("❌ Infinite loop detected. Aborting.")
                break
            }
            
            let visibleRange = NSRange(location: currentLocation, length: fullLength - currentLocation)
            let visibleText = fullText.attributedSubstring(from: visibleRange)
            
            let textStorage = NSTextStorage(attributedString: visibleText)
            let layoutManager = NSLayoutManager()
            textStorage.addLayoutManager(layoutManager)
            
            let textContainer = NSTextContainer(size: maxSize)
            textContainer.lineFragmentPadding = 0
            layoutManager.addTextContainer(textContainer)
            
            layoutManager.ensureLayout(for: textContainer)
            
            let glyphRange = layoutManager.glyphRange(for: textContainer)
            if glyphRange.length == 0 {
                print("⚠️ Empty glyph range. Ending pagination.")
                break
            }
            
            let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
            if charRange.length == 0 {
                print("⚠️ Empty character range. Ending pagination.")
                break
            }
            
            let actualRange = NSRange(location: currentLocation + charRange.location, length: charRange.length)
            let pageText = fullText.attributedSubstring(from: actualRange)
            
            results.append((text: pageText, range: actualRange))
        //    print("✅ Page \(results.count): Range \(actualRange)")
            
            currentLocation = actualRange.location + actualRange.length
        }
        return results
    }
}

extension PagedTextViewController {
  
    
    func navigateToPage(index: Int) {
        guard index >= 0, index < pagess.count else { return }
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
        guard index >= 0 && index < chunkedPages.count else { return nil }
        viewControllerCache[index] = nil  // ✅ force clear old one
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "TextPageViewController") as? TextPageViewController else {
            return nil
        }

        vc.pageNavigationDelegate = self
        vc.pageIndex = index
        vc.pageController = self
        vc.searchKeyword = self.searchKeyword
        vc.isRotationLocked = isRotationLocked
        vc.lockedOrientation = lockedOrientation
        vc.bookChapterrs = self.bookChapterrs
        vc.pagess = self.pagess
        vc.chunkedPages = self.chunkedPages
        let content = chunkedPages[index]
        vc.pageContentt = content
        let savedFontSize = UserDefaults.standard.float(forKey: "globalFontSize")
        if savedFontSize > 0 {
            vc.applyFontSize(CGFloat(savedFontSize))
        }
        viewControllerCache[index] = vc  // ✅ cache the fresh one
        return vc
    }

    func viewControllerForPage(_ pageIndex: Int) -> TextPageViewController? {
        guard pageIndex >= 0 && pageIndex < chunkedPages.count else { return nil }
        let vc = TextPageViewController()
        vc.pageController = self
        vc.pageIndex = pageIndex
        vc.bookChapterrs = self.bookChapterrs
        vc.pagess = self.pagess
        vc.chunkedPages = self.chunkedPages
        let content = chunkedPages[pageIndex]
        vc.pageContentt = content

        return vc
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? TextPageViewController else { return nil }
        vc.pageController = self
        return getViewController(at: vc.pageIndex - 1)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? TextPageViewController else { return nil }
        vc.pageController = self
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
                textVC.pageContentt = self.chunkedPages.first!
                textVC.pageController = self
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    textVC.refreshContent()//
                     textVC.reloadPageContent()
                     textVC.closeMenu()
                     textVC.closeNote()
                }
               
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
            visibleVC.pageController = self
            self.currentIndex = visibleVC.pageIndex
            self.pageControl.currentPage = self.currentIndex
            self.pageChangeDelegate?.didUpdatePage(to: self.currentIndex)
           
        }
    }
}

extension PagedTextViewController {
    func goToPage(index: Int) {
        guard index >= 0, index < pagess.count else {
            print("❌ Invalid page index: \(index)")
            return
        }
        
        let direction: UIPageViewController.NavigationDirection = (index >= currentIndex) ? .forward : .reverse
        let newVC = TextPageViewController()
        newVC.pageIndex = index
        newVC.pageController = self
        newVC.pageNavigationDelegate = self
        newVC.bookChapterrs = self.bookChapterrs
        newVC.pagess = self.pagess
        newVC.pageContentt = chunkedPages[index]
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
        firstVC.pageController = self
       // print("✅ Found active TextPageViewController.")
        return firstVC
    }

    func clearAdjacentViewControllerCache() {
        viewControllerCache[currentIndex - 1] = nil
        viewControllerCache[currentIndex] = nil
        viewControllerCache[currentIndex + 1] = nil
        
    }

    func recreateViewController(at index: Int) -> TextPageViewController? {
        guard index >= 0 && index < pagess.count else { return nil }
        let vc = TextPageViewController()
        vc.pageController = self
        vc.pageIndex = index
        vc.bookChapterrs = self.bookChapterrs
        vc.pagess = self.pagess
        vc.pageContentt = chunkedPages[index]
        vc.applySavedAppearance()
        vc.refreshContent()
        vc.reloadPageContent()
        viewControllerCache[index] = vc  // ✅ cache it
        return vc
    }

    func updatePageControl() {
        pageControl.numberOfPages = self.chunkedPages.count
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

    func fetchFirstToken(bookID: Int, tokenID: Int, completion: @escaping (Result<Chapterr, ErorrMessage>) -> Void) {
        NetworkService.shared.getResults(
            APICase: .fetchFirstToken(bookID: bookID, tokenID: tokenID),
            decodingModel: Chapterr.self
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
    
    private func mapToBookState(bookResponse: BookResponse, metadata: MetaDataResponse, bookContent: Chapterr) -> BookState {
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
    
       private func extractChapters(from bookContent: Chapterr) -> [ChapterData] {
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
        
        for index in 0..<pagess.count {
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
           if isRotationLocked, let lockedOrientation = lockedOrientation {
               print("🔒 Rotation is LOCKED to: \(lockedOrientation.rawValue)")
           } else {
             //  print("🔄 Rotation is UNLOCKED: Device can rotate freely.")
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
        for (index, viewController) in viewControllerCache {
            viewController.reloadPageContent()
        }
    }
}

