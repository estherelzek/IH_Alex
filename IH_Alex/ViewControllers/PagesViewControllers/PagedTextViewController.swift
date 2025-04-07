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

enum ScrollMode: String {
    case horizontalPaging = "horizontal"
    case verticalScrolling = "vertical"
}

class PagedTextViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
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
    
    var scrollMode: ScrollMode = .horizontalPaging {
        didSet {
            UserDefaults.standard.set(scrollMode == .horizontalPaging ? "horizontal" : "vertical", forKey: "scrollMode")
            switchScrollMode()
        }
    }

       var isRotationLocked = false
       var lockedOrientation: UIInterfaceOrientation?
   
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
        
        if let firstVC = getViewController(at: currentIndex) {
            setViewControllers([firstVC], direction: .forward, animated: false, completion: nil)
            print("✅ First page set")
        } else {
            print("❌ Failed to create first page")
        }
        detectInitialOrientation()
        restoreRotationLock()
        let isScreenAlwaysOn = UserDefaults.standard.bool(forKey: "keepDisplayOn")
        UIApplication.shared.isIdleTimerDisabled = isScreenAlwaysOn
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
    
    func processMultipleBookContents(_ contents: [BookContent], book: Book, metadata: MetaDataResponse) -> [PageContent] {
        var allPages: [PageContent] = []

        for content in contents {
            let processedPages = processBookContent(content, book: book, metadata: metadata)
            allPages.append(contentsOf: processedPages)
        }

        return allPages
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
     //   print("decryptedText Text: \(decryptedText)")
        let parsedPages = ParsePage().invoke(pageEncodedString: decryptedText, metadata: metadata, book: book)
      //  print("parsedPages:\(parsedPages)")
        var processedPages: [PageContent] = []
        for attributedText in parsedPages {
            processedPages.append(PageContent(attributedText: attributedText, image: nil))
        }
        return processedPages
    }
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

    func getViewController(at index: Int) -> TextPageViewController? {
           guard index >= 0 && index < pages.count else { return nil }
           let storyboard = UIStoryboard(name: "Main", bundle: nil)
           if let vc = storyboard.instantiateViewController(withIdentifier: "TextPageViewController") as? TextPageViewController {
               vc.pageContent = pages[index]
               vc.pageIndex = index
               vc.pageController = self // ✅ Ensure reference to update all pages
               let savedFontSize = UserDefaults.standard.float(forKey: "globalFontSize")
               if savedFontSize > 0 {
                //   print("savedFontSize: \(savedFontSize)")
                   vc.applyFontSize(CGFloat(savedFontSize))
               }
                vc.isRotationLocked = isRotationLocked
                vc.lockedOrientation = lockedOrientation
               return vc
           }
           return nil
       }

}
extension PagedTextViewController {
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
            // 🔓 Unlock rotation
            isRotationLocked = false
            lockedOrientation = nil
            print("🔄 Rotation Unlocked: Now follows device movement")
            UserDefaults.standard.set(false, forKey: "rotationLocked")
            UserDefaults.standard.removeObject(forKey: "lockedOrientation")
            // ✅ Allow all orientations
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
    func navigateToPage(_ index: Int) {
        guard let targetVC = getViewController(at: index) else { return }
        let direction: UIPageViewController.NavigationDirection = index > currentIndex ? .forward : .reverse
        setViewControllers([targetVC], direction: direction, animated: true, completion: nil)
        currentIndex = index
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
        return 0
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return currentIndex
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            willTransitionTo pendingViewControllers: [UIViewController]) {
        if let nextVC = pendingViewControllers.first as? TextPageViewController {
            nextVC.applySavedAppearance() // ✅ Apply font size before next page appears
            nextVC.reloadPageContent()
        }

        if let currentVC = pageViewController.viewControllers?.first as? TextPageViewController {
            currentVC.closeMenu() // ✅ Instantly close menu before scrolling starts
            currentVC.closeNote()
            currentVC.reloadPageContent()
            
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        guard completed,
              let visibleVC = pageViewController.viewControllers?.first as? TextPageViewController
        else { return }
        currentIndex = visibleVC.pageIndex
        print("📄 Current Page Index: \(currentIndex)")
        pageControl.currentPage = currentIndex
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
    func reedFiles(){
        if let bookInfo: BookResponse = loadJSON(from: "Bookinfo", as: BookResponse.self) {
            self.bookResponse = bookInfo
        //    print("✅ bookInfo loaded: \(bookResponse)")
        }
        if let metadataa: MetaDataResponse = loadJSON(from: "metadataResponse", as: MetaDataResponse.self) {
            self.metadataa = metadataa
      //      print("✅ Metadata loaded: \(metadataa)")
        }
        
        let tokens = ["Token1", "Token2", "Token3", "Token4"]
        for token in tokens {
            if let bookContent: BookContent = loadJSON(from: token, as: BookContent.self) {
                bookContents.append(bookContent)
       //         print("✅ Loaded: \(token)")
            } else {
                print("❌ Failed to load \(token)")
            }
        }
        guard !bookContents.isEmpty else {
            print("❌ No book content loaded.")
            return
        }
        self.pages = self.processMultipleBookContents(
            bookContents,
            book: bookResponse?.book ?? Book.default,
            metadata: metadataa ?? MetaDataResponse.default
        )
              let mergedContent = bookContents.reduce(BookContent.default) { $0.merge(with: $1) }
              if let bookInfo = bookResponse {
                  self.bookState = mapToBookState(bookResponse: bookInfo, metadata: metadataa ?? MetaDataResponse.default, bookContent: mergedContent)
            //      print("✅ BookState created: \(self.bookState!)")
              }
    }

}
