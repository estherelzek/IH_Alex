//
//  TextPageViewController.swift
//  IH_Alex
//
//  Created by esterelzek on 16/02/2025.
//
import UIKit
protocol PageNavigationDelegate: AnyObject {
    func navigateToPage(index: Int)
}
extension TextPageViewController {
    func navigateToPage(at index: Int) {
        pageController?.goToPage(index: index)
    }
}
protocol InternalLinkNavigationDelegate: AnyObject {
    func didNavigateToInternalLink(pageIndex: Int)
}

class TextPageViewController: UIViewController, UITextViewDelegate,BookmarkViewDelegate,CustomMenuDelegate {
    var menuButton: UIButton!
   // var pageContent: ChapterPages?
    var pageIndex: Int = 0
    let textView = UITextView()
    var bookmarkView: BookmarkView?
    var pageController: PagedTextViewController?
    var menuVC: MenuViewController?
    var isRotationLocked = false
    var lockedOrientation: UIInterfaceOrientation?
    var noteVC: NoteViewController?
    weak var delegate: MenuViewDelegate?
    var pages: [ChapterPages] = []
    var originalPages: [OriginalPage] = []
    var bookChapters: [Chapter] = []
    weak var pageNavigationDelegate: PageNavigationDelegate?
    weak var internalLinkDelegate: InternalLinkNavigationDelegate?
    var searchKeyword: String?
    var searchResults: [SearchResult] = []

    //
    var bookChapterrs: [Chapterr] = []
    var pagess: [Page] = []
    var chunkedPages: [Chunk] = []  // This is rebuilt every time
    var pageContentt: Chunk?
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        if let pageContent = pageContentt {
           loadHighlights(for: pageContent)
        } else {
            print("❌ No page content available — cannot load highlights.")
        }
        setupTextView()
        setupCustomMenu()
    
        applySavedAppearance()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.loadNoteIcons()
            self.addBookmarkView()
        }
    //    setupMenuButton()
        setUpBritness()
        restoreBrightness()
        NotificationCenter.default.addObserver(self, selector: #selector(bookmarkUpdated(_:)), name: Notification.Name("BookmarkUpdated"), object: nil)
        reloadPageContent()
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.loadNoteIcons()
       self.addBookmarkView()
      
    }
    
    func setupTextView() {
        textView.isEditable = false
        textView.isSelectable = true
        textView.isUserInteractionEnabled = true
        textView.dataDetectorTypes = .link
        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textAlignment = .right
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        if let attributedContent = pageContentt?.attributedText {
            textView.attributedText = applyLanguageBasedAlignment(to: attributedContent)
        }

        view.addSubview(textView)
        let isHorizontalPaging = pageController?.scrollMode == .horizontalPaging
        let topPadding: CGFloat = isHorizontalPaging ? 60 : 60
        let bottomConstraint = textView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10)
        bottomConstraint.priority = UILayoutPriority(750) // Lower priority to avoid conflicts

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            bottomConstraint
        ])
    }

    func applySavedAppearance() {
        let savedFontSize = UserDefaults.standard.value(forKey: "globalFontSize") as? CGFloat ?? 16
        let savedBackground = UserDefaults.standard.color(forKey: "globalBackgroundColor") ?? .white
        let savedFontColor = UserDefaults.standard.color(forKey: "globalFontColor") ?? .black
        let savedLineSpacing = UserDefaults.standard.value(forKey: "globalLineSpacing") as? CGFloat ?? 1
        applyAppearanceAttributes(fontColor: savedFontColor, backgroundColor: savedBackground, fontSize: savedFontSize)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {
            self.applyLineSpacing(savedLineSpacing)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        closeMenu()
        reloadPageContent()
    }
  
    private func setupPageViewController() {
            pageController = PagedTextViewController()
            if let pageController = pageController {
                addChild(pageController)
                pageController.view.frame = view.bounds
                view.addSubview(pageController.view)
                pageController.didMove(toParent: self)
            }
        }
    
    func setUpBritness(){
        if let savedBrightness = UserDefaults.standard.value(forKey: "savedBrightness") as? Float {
                UIScreen.main.brightness = CGFloat(savedBrightness) // Restore brightness
            }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let pageContent = pageContentt {
            loadHighlights(for: pageContent)
            loadNoteIcons()
            addBookmarkView()
            reloadPageContent()
        }
    }

    private func restoreBrightness() {
        DispatchQueue.main.async {
          //  print("🌞 Before setting brightness: \(UIScreen.main.brightness)")
            UIScreen.main.brightness = 1.0 // Set brightness
         //   print("🌞 After setting brightness: \(UIScreen.main.brightness)") // Debugging
        }
    }
        @objc  func toggleMenu() {
            if menuVC != nil {
                closeMenu()
            } else {
                showMenu()
            }
        }

     func showMenu() {
        let menuVC = MenuViewController()
        menuVC.delegate = self
         menuVC.modalPresentationStyle = .overCurrentContext // So the parent stays underneath
        menuVC.view.backgroundColor = UIColor.black.withAlphaComponent(0.0) // Semi-transparent
        menuVC.modalTransitionStyle = .crossDissolve   // Optional: for a smooth fade
        self.present(menuVC, animated: true, completion: nil)
    }
    
    func closeMenu() {
        let preservedAbsoluteLocation: Int
        print("📍 pageIndex: \(pageIndex)")
        print("📍 pages count: \(chunkedPages.count)")

        guard chunkedPages.indices.contains(pageIndex) else {
            print("📍 Invalid pageIndex: \(pageIndex), out of bounds.")
            return
        }

//        let currentPage = chunkedPages[pageIndex]
//        let previousOriginalPagesLength = originalPages
//            .prefix(while: { $0.index < currentPage.originalPageIndex })
//            .map { $0.fullAttributedText.length }
//            .reduce(0, +)
//
//        preservedAbsoluteLocation = previousOriginalPagesLength + currentPage.rangeInOriginal.location
//        print("📍 Preserved absolute location: \(preservedAbsoluteLocation) for current visible page \(pageIndex)")

        // ✅ Get the current values
        let finalFontSize = UserDefaults.standard.float(forKey: "globalFontSize")
        let screenSize = view.bounds.inset(by: UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)).size

        // ✅ Get previous stored values
        let lastFontSize = UserDefaults.standard.float(forKey: "lastFontSize")
        let lastScreenWidth = UserDefaults.standard.float(forKey: "lastScreenWidth")
        let lastScreenHeight = UserDefaults.standard.float(forKey: "lastScreenHeight")

        // ✅ Check if they are different before rebuilding
        if finalFontSize != lastFontSize || screenSize.width != CGFloat(lastScreenWidth) || screenSize.height != CGFloat(lastScreenHeight) {
            print("🔄 Detected change in font size or screen size, rebuilding pages...")

            // ✅ Update the stored values
            UserDefaults.standard.set(finalFontSize, forKey: "lastFontSize")
            UserDefaults.standard.set(Float(screenSize.width), forKey: "lastScreenWidth")
            UserDefaults.standard.set(Float(screenSize.height), forKey: "lastScreenHeight")

        guard let newChunks = self.pageController?.createChunks(fontSize: CGFloat(finalFontSize), screenSize: screenSize) else {
                  print("❌ Failed to create chunks.")
                  return
              }

              self.pageController?.chunkedPages = newChunks
              self.chunkedPages = newChunks

              pageIndex = min(pageIndex, chunkedPages.count - 1)

              DispatchQueue.main.async {
                  self.pageController?.updatePageControl()
                  self.refreshContent()
                  self.reloadPageContent()
              }
          } else {
              print("✅ No changes detected, skipping rebuild.")
          }
        menuVC?.willMove(toParent: nil)
        menuVC?.view.removeFromSuperview()
        menuVC?.removeFromParent()
        self.menuVC = nil
        self.pageController?.refreshAllPages()
    }


    func closeNote() {
        if let menuVC = noteVC {
            menuVC.willMove(toParent: nil)
            menuVC.view.removeFromSuperview()
            menuVC.removeFromParent()
            self.noteVC = nil
        }
    }

}

extension TextPageViewController: MenuViewDelegate {
    func menuDidClose() {
        DispatchQueue.main.async {
            self.closeMenu()
        }
    }

    
    func keepDisplayOn() {
            let isScreenAlwaysOn = !UserDefaults.standard.bool(forKey: "keepDisplayOn")
            UserDefaults.standard.set(isScreenAlwaysOn, forKey: "keepDisplayOn")
            UIApplication.shared.isIdleTimerDisabled = isScreenAlwaysOn
            print(isScreenAlwaysOn ? "✅ Screen will remain on" : "⏳ Screen will turn off after inactivity")
        }


    func rotateScreen() {
        guard let pageController = pageController else {
            print("❌ `pageController` is nil. Rotation cannot be locked.")
            return
        }
        print("📌 Calling toggleRotationLock() from Menu")
        pageController.toggleRotationLock()
    }
    
    func changeLineSpacing(wide: Bool) {
        let lineSpacing = wide ? 12 : 1
        UserDefaults.standard.set(lineSpacing, forKey: "globalLineSpacing")
        UserDefaults.standard.synchronize()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.applyLineSpacing(CGFloat(lineSpacing))
            self.pageController?.applyLineSpacingToAllPages(CGFloat(lineSpacing))
        }
    }
    
    func zoom(increase: Bool) {
        let step: CGFloat = 1.0
        guard let currentFont = textView.attributedText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont else {
            print("⚠️ No font found in attributed text!")
            return
        }

        let currentSize = currentFont.pointSize
        let newFontSize = increase ? currentSize + step : currentSize - step
        let finalFontSize = max(min(newFontSize, 30), 12)

        print("🔹 Before Zoom | Current Size: \(currentSize), New Size: \(newFontSize), Final Size: \(finalFontSize)")

        if finalFontSize == currentSize {
            if finalFontSize == 30 {
                print("🔹 Font size is already at the maximum limit (30). Skipping update.")
            } else if finalFontSize == 12 {
                print("🔹 Font size is already at the minimum limit (12). Skipping update.")
            } else {
                print("🔹 Font size unchanged. Skipping update.")
            }
            return
        }

        UserDefaults.standard.set(finalFontSize, forKey: "globalFontSize")
        UserDefaults.standard.synchronize()
        print("✅ Saved finalFontSize: \(finalFontSize)")

        // Apply the font size
        applyFontSize(finalFontSize)
        pageController?.applyFontSizeToAllPages(finalFontSize)
        loadNoteIcons()
    }

    func refreshContent() {
        guard let pageController = self.pageController else { return }
        let latestContent = pageController.chunkedPages[pageIndex]
        pageContentt = latestContent
        textView.attributedText = applyLanguageBasedAlignment(to: latestContent.attributedText)
        textView.setContentOffset(.zero, animated: false)
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    func applyFontSize(_ fontSize: CGFloat) {
        let mutableAttributedText = NSMutableAttributedString(attributedString: textView.attributedText)
        mutableAttributedText.enumerateAttributes(in: NSRange(location: 0, length: mutableAttributedText.length), options: []) { attributes, range, _ in
            let existingFont = attributes[.font] as? UIFont ?? UIFont.systemFont(ofSize: 16)
            let newFont = existingFont.withSize(fontSize)
            mutableAttributedText.addAttribute(.font, value: newFont, range: range)
        }
        DispatchQueue.main.async {
            self.textView.attributedText = mutableAttributedText
        }
    }

    func applyLineSpacing(_ lineSpacing: CGFloat) {
        let mutableAttributedText = NSMutableAttributedString(attributedString: textView.attributedText)
        mutableAttributedText.enumerateAttributes(in: NSRange(location: 0, length: mutableAttributedText.length), options: []) { attributes, range, _ in
            var newAttributes = attributes
            if let existingFont = attributes[.font] as? UIFont {
                newAttributes[.font] = existingFont
            }
            if let existingColor = attributes[.foregroundColor] as? UIColor {
                newAttributes[.foregroundColor] = existingColor
            }
            if let existingUnderline = attributes[.underlineStyle] {
                newAttributes[.underlineStyle] = existingUnderline
            }
            let updatedParagraphStyle = (attributes[.paragraphStyle] as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
            updatedParagraphStyle.lineSpacing = lineSpacing
            newAttributes[.paragraphStyle] = updatedParagraphStyle
            mutableAttributedText.setAttributes(newAttributes, range: range)
        }
        DispatchQueue.main.async {
            self.textView.attributedText = mutableAttributedText
        }
    }

    func changeBackgroundAndFontColor(background: UIColor, font: UIColor) {
        applyAppearanceAttributes(fontColor: font, backgroundColor: background)
        UserDefaults.standard.setColor(background, forKey: "globalBackgroundColor")
        UserDefaults.standard.setColor(font, forKey: "globalFontColor")
        UserDefaults.standard.synchronize()
        let savedBackground = UserDefaults.standard.color(forKey: "globalBackgroundColor") ?? .white
        print("✅ Background Color Saved: \(savedBackground)")
        pageController?.applyBackgroundAndFontColorToAllPages(background: background, font: font)
    }

    func applyAppearanceAttributes(fontColor: UIColor, backgroundColor: UIColor, fontSize: CGFloat? = nil, lineSpacing: CGFloat? = nil) {
        let mutableAttributedText = NSMutableAttributedString(attributedString: textView.attributedText)
       // print("🔹 Applying Appearance | FontSize: \(fontSize ?? 0), LineSpacing: \(lineSpacing ?? 0)")
        mutableAttributedText.enumerateAttributes(in: NSRange(location: 0, length: mutableAttributedText.length), options: []) { attributes, range, _ in
            let existingFont = attributes[.font] as? UIFont ?? UIFont.systemFont(ofSize: 16)
            let newFontSize = fontSize ?? existingFont.pointSize
            let newFont = UIFont(descriptor: existingFont.fontDescriptor, size: newFontSize)

            let updatedParagraphStyle = (attributes[.paragraphStyle] as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
            updatedParagraphStyle.lineSpacing = lineSpacing ?? updatedParagraphStyle.lineSpacing
            mutableAttributedText.addAttribute(.font, value: newFont, range: range)
            mutableAttributedText.addAttribute(.foregroundColor, value: fontColor, range: range)
            mutableAttributedText.addAttribute(.paragraphStyle, value: updatedParagraphStyle, range: range)
        }
        DispatchQueue.main.async {
            self.textView.attributedText = mutableAttributedText
            self.textView.backgroundColor = backgroundColor
        }
    }

    func adjustBrightness(value: Float) {
        DispatchQueue.main.async {
            let brightnessValue = CGFloat(value)
            UIScreen.main.brightness = brightnessValue
            UserDefaults.standard.set(value, forKey: "savedBrightness")
            print("🌞 Brightness Set to: \(UIScreen.main.brightness)")
        }
    }
    
    func changeScrollMode(to mode: ScrollMode) {
        UserDefaults.standard.set(mode.rawValue, forKey: "savedScrollMode") // Save mode
        UserDefaults.standard.synchronize()

        if let pageController = pageController {
            print("mode: \(mode)")
            pageController.scrollMode = mode  // Apply scrolling mode
        }
    }
}

// MARK: - NoteViewControllerDelegate
extension TextPageViewController: NoteViewControllerDelegate {
    func didSaveNote() {
        DispatchQueue.main.async {
            self.loadNoteIcons()
        }
    }

    func didDeleteNote() {
        DispatchQueue.main.async {
            self.loadNoteIcons()
        }
    }

    func reloadPageContent() {
        guard let pageContent = self.pageContentt else {
            print("❌ No pageContent to reload.")
            return
        }

        // Re-apply attributed text
        self.textView.attributedText = applyLanguageBasedAlignment(to: pageContent.attributedText)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
        self.loadHighlights(for: pageContent)
        self.loadNoteIcons()
       self.applySavedAppearance()
        self.addBookmarkView()
    }
    }

    func reloadContent(at index: Int) {
        guard chunkedPages.indices.contains(index) else {
            print("❌ Index \(index) out of bounds. Cannot reload.")
            return
        }
        pageIndex = index
        guard let pageController = self.pageController else { return }
        let latestContent = pageController.chunkedPages[pageIndex]
        print("pageIndex: \(pageIndex)")
        print("pageIndex content: \(chunkedPages[pageIndex].attributedText)")

        pageContentt = latestContent
        textView.attributedText = applyLanguageBasedAlignment(to: latestContent.attributedText)
        textView.setContentOffset(.zero, animated: false)
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    func copySelectedText() {
            if let selectedText = textView.text(in: textView.selectedTextRange!) {
                UIPasteboard.general.string = selectedText
            }
        }

    func shareSelectedText() {
            if let selectedText = textView.text(in: textView.selectedTextRange!) {
                let activityVC = UIActivityViewController(activityItems: [selectedText], applicationActivities: nil)
                present(activityVC, animated: true)
            }
        }
}

extension TextPageViewController {
    func addNote() {
            guard let selectedRange = textView.selectedTextRange,
                  let selectedText = textView.text(in: selectedRange),
                  let pageContent = pageContentt else { return }

            let nsRange = getNSRange(from: selectedRange) ?? NSRange(location: 0, length: 0)

            let globalRange = NSRange(
                location: pageContent.globalStartIndex + nsRange.location,
                length: nsRange.length
            )

               let noteVC = NoteViewController(nibName: "NoteViewController", bundle: nil)
               noteVC.noteTitleContent = selectedText
               noteVC.noteTextContent = ""
               noteVC.noteRange = globalRange
               noteVC.originalPageIndex = pageIndex
               noteVC.delegate = self
        noteVC.originalPageBody = pagess[pageIndex].body
        noteVC.bookChapterrs = bookChapterrs
        noteVC.pagess = pagess
        noteVC.chunkedPages = chunkedPages
        noteVC.pageContentt = pageContentt
        noteVC.bookId = bookChapterrs.first?.bookID
      
            noteVC.view.frame = CGRect(x: -10, y: -10, width: view.frame.width - 80, height: view.frame.height - 80)
            noteVC.view.center = view.center
            addChild(noteVC)
            view.addSubview(noteVC.view)
            noteVC.didMove(toParent: self)
            self.noteVC = noteVC
        }


    func getNSRange(from textRange: UITextRange) -> NSRange? {
        let location = textView.offset(from: textView.beginningOfDocument, to: textRange.start)
        let length = textView.offset(from: textRange.start, to: textRange.end)
        return NSRange(location: location, length: length)
    }

    @objc func dismissNoteView() {
        if let backgroundView = view.viewWithTag(999) {
            backgroundView.removeFromSuperview()
        }
        for child in children {
            if child is NoteViewController {
                child.willMove(toParent: nil)
                child.view.removeFromSuperview()
                child.removeFromParent()
            }
        }
    }

    func loadNoteIcons() {
        guard let bookId = bookChapterrs.first?.bookID else {
            print("❌ Missing bookId")
            return
        }

        textView.subviews.forEach { subview in
            if subview is UIImageView { subview.removeFromSuperview() }
        }

        guard let pageContent = pageContentt else { return }

        let notes = NoteManager.shared.loadNotes().filter { note in
            note.bookId == bookId &&
            note.pageNumberInChapter == pageContent.pageNumberInChapter &&
            note.chapterNumber == pageContent.chapterNumber &&
            note.start < pageContent.globalEndIndex &&
            note.end > pageContent.globalStartIndex
        }

        for note in notes {
            let localLocation = note.start - pageContent.globalStartIndex
            guard localLocation >= 0 else { continue }

            let startOffset = localLocation
            let endOffset = startOffset + (note.end - note.start)

            if let start = textView.position(from: textView.beginningOfDocument, offset: startOffset),
               let end = textView.position(from: textView.beginningOfDocument, offset: endOffset),
               let textRange = textView.textRange(from: start, to: end) {
                let textRect = textView.firstRect(for: textRange)
                let textViewFrame = textView.convert(textView.bounds, to: view)
                let leftMargin = textViewFrame.minX

                let noteIcon = UIImageView(image: UIImage(systemName: "square.and.pencil"))
                noteIcon.tintColor = .systemBlue
                noteIcon.frame = CGRect(x: leftMargin, y: textRect.minY, width: 20, height: 20)
                noteIcon.isUserInteractionEnabled = true
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(noteIconTapped(_:)))
                noteIcon.addGestureRecognizer(tapGesture)
                noteIcon.tag = note.id.hashValue  // Use unique note ID for identification
                textView.addSubview(noteIcon)
            }
        }
    }

    @objc func noteIconTapped(_ sender: UITapGestureRecognizer) {
        guard let tappedIcon = sender.view as? UIImageView else { return }
        let noteIdHash = tappedIcon.tag

        let allNotes = NoteManager.shared.loadNotes()
        if let tappedNote = allNotes.first(where: { $0.id.hashValue == noteIdHash }) {
            showNoteForNoteId(tappedNote.id)
        }
    }

    func showNoteForNoteId(_ noteId: Int64) {
          print("noteId: \(noteId)")
          let allNotes = NoteManager.shared.loadNotes()
          guard let note = allNotes.first(where: { $0.id == noteId }) else { return }

          let noteVC = NoteViewController(nibName: "NoteViewController", bundle: nil)
          noteVC.noteTitleContent = note.selectedNoteText
          noteVC.noteTextContent = note.noteText
          noteVC.bookId = note.bookId
          noteVC.noteId = noteId
          noteVC.bookChapterrs = bookChapterrs
          noteVC.pagess = pagess
          noteVC.chunkedPages = chunkedPages
          noteVC.pageContentt = pageContentt
          noteVC.delegate = self
          noteVC.isEdit = true
          if let pageContent = pageContentt {
              let localStart = max(0, note.start - pageContent.globalStartIndex)
              let length = max(0, min(note.end, pageContent.globalEndIndex) - note.start)
              noteVC.noteRange = NSRange(location: localStart, length: length)
          }

          noteVC.view.frame = CGRect(x: -10 , y: -10, width: view.frame.width - 60, height: view.frame.height - 80)
          noteVC.view.center = view.center
          addChild(noteVC)
          view.addSubview(noteVC.view)
          noteVC.didMove(toParent: self)
          self.noteVC = noteVC
      }

    
    func applyHighlight(color: UIColor) {
        guard let selectedRange = textView.selectedTextRange,
              let text = textView.text(in: selectedRange),
              let nsRange = getNSRange(from: selectedRange),
              nsRange.length > 0,
              let currentPageContent = getCurrentPageContent() else {
            print("No valid selection or page content")
            return
        }

        let globalStart = nsRange.location + currentPageContent.globalStartIndex
        let globalEnd = globalStart + nsRange.length

        let highlight = Highlight(
            serverId: nil,
            id: Int64(Date().timeIntervalSince1970 * 1000), // Temporary unique local ID
            bookId: bookChapterrs.first?.bookID ?? 0,
            chapterNumber: currentPageContent.chapterNumber,
            pageNumberInChapter: currentPageContent.pageNumberInChapter,
            pageNumberInBook: currentPageContent.pageIndexInBook,
            start: globalStart,
            end: globalEnd,
            text: text,
            color: color.toHexInt(),
            lastUpdated: Date()
        )
        
       print("highlight: \(highlight)")
        HighlightManager.shared.saveHighlight(highlight)
        updateTextViewHighlight(range: nsRange, color: color)
    }



    func calculateGlobalRange(from nsRange: NSRange, pageContent: Chunk) -> NSRange {
        let globalStart = nsRange.location + pageContent.globalStartIndex
        return NSRange(location: globalStart, length: nsRange.length)
    }

    func updateTextViewHighlight(range: NSRange, color: UIColor) {
        textView.textStorage.beginEditing()
        textView.textStorage.addAttribute(.backgroundColor, value: color, range: range)
        textView.textStorage.endEditing()
    }

    func getCurrentPageContent() -> Chunk? {
        return chunkedPages.first { $0.pageIndexInBook == pageIndex }
    }

    func clearHighlight() {
        guard let selectedRange = textView.selectedTextRange,
              let nsRange = getNSRange(from: selectedRange),
              let currentPageContent = getCurrentPageContent() else {
            return
        }

        let globalRange = NSRange(
            location: nsRange.location + currentPageContent.globalStartIndex,
            length: nsRange.length
        )

        var highlights = HighlightManager.shared.loadHighlights()
        highlights.removeAll {
            NSIntersectionRange(NSRange(location: $0.start, length: $0.end - $0.start), globalRange).length > 0 &&
            $0.pageNumberInBook == currentPageContent.pageIndexInBook
        }

        HighlightManager.shared.saveAllHighlights(highlights)
        refreshTextViewHighlights()
    }

    func refreshTextViewHighlights() {
        guard let currentPageContent = getCurrentPageContent() else { return }

        let fullRange = NSRange(location: 0, length: textView.textStorage.length)
        let highlights = HighlightManager.shared.loadHighlights()
            .filter { highlight in
                highlight.start < currentPageContent.globalEndIndex &&
                highlight.end > currentPageContent.globalStartIndex
            }

        textView.textStorage.beginEditing()
        textView.textStorage.removeAttribute(.backgroundColor, range: fullRange)

        for highlight in highlights {
            let localStart = highlight.start - currentPageContent.globalStartIndex
            let localRange = NSRange(location: localStart, length: highlight.end - highlight.start)
            if localRange.location >= 0 && NSMaxRange(localRange) <= fullRange.length {
                textView.textStorage.addAttribute(.backgroundColor, value: UIColor(rgb: highlight.color), range: localRange)
            }
        }

        textView.textStorage.endEditing()
    }

    func loadHighlights(for pageContent: Chunk) {
        guard let bookId = bookChapterrs.first?.bookID else {
            print("❌ Missing bookId")
            return
        }

        let chapterNumber = pageContent.chapterNumber
        let fullRange = NSRange(location: 0, length: textView.textStorage.length)
        // Filter highlights that match this book & chapter AND overlap the page range
        let highlights = HighlightManager.shared.loadHighlights().filter { h in
            h.bookId == bookId &&
            h.pageNumberInChapter == pageContent.pageNumberInChapter &&
            h.chapterNumber == chapterNumber &&
            h.start < pageContent.globalEndIndex &&
            h.end > pageContent.globalStartIndex
        }

        textView.textStorage.beginEditing()
        textView.textStorage.removeAttribute(.backgroundColor, range: fullRange)

        for highlight in highlights {
            let localStart = highlight.start - pageContent.globalStartIndex
            let length = highlight.end - highlight.start
            let localRange = NSRange(location: localStart, length: length)
            if localRange.location >= 0 && NSMaxRange(localRange) <= textView.textStorage.length {
                textView.textStorage.addAttribute(.backgroundColor, value: UIColor(rgb: highlight.color), range: localRange)
            } else {
                print("⚠️ Skipped out-of-bounds highlight: \(highlight)")
            }
        }
        // Apply search highlights if any
        for result in searchResults {
            let lowerText = textView.text.lowercased()
            let searchText = result.content.lowercased()
            var range = lowerText.startIndex..<lowerText.endIndex

            while let match = lowerText.range(of: searchText, options: [], range: range) {
                let nsRange = NSRange(match, in: lowerText)
                textView.textStorage.addAttribute(.backgroundColor, value: UIColor.systemCyan.withAlphaComponent(0.2), range: nsRange)
                range = match.upperBound..<range.upperBound
            }
        }
        textView.textStorage.endEditing()
    }

    func deleteNoteForNoteId(_ noteId: Int64) {
        var allNotes = NoteManager.shared.loadNotes()
        allNotes.removeAll { $0.id == noteId }
        NoteManager.shared.saveAllNotes(allNotes)

        DispatchQueue.main.async {
            self.refreshTextViewNotes()
            self.loadNoteIcons()
        }
    }


    func refreshTextViewNotes() {
        let attributedString = NSMutableAttributedString(attributedString: textView.attributedText)
        attributedString.enumerateAttribute(.link, in: NSRange(location: 0, length: attributedString.length)) { value, range, _ in
            if let link = value as? String, link.starts(with: "note:") {
                attributedString.removeAttribute(.link, range: range)
                attributedString.replaceCharacters(in: range, with: "") // Remove old attachment
            }
        }

        guard let pageContent = pageContentt else { return }
        let notes = NoteManager.shared.loadNotes().filter { note in
            let noteRange = note.start..<note.end
            let pageRange = pageContent.globalStartIndex..<pageContent.globalEndIndex
            return noteRange.overlaps(pageRange)
        }

        for note in notes {
            let noteAttachment = NSTextAttachment()
            noteAttachment.image = UIImage(systemName: "note.text")
            let noteString = NSAttributedString(attachment: noteAttachment)
            let noteIconAttributedString = NSMutableAttributedString(attributedString: noteString)
            noteIconAttributedString.addAttribute(.link, value: "note:\(note.id)", range: NSRange(location: 0, length: noteIconAttributedString.length))

            let insertIndex = note.start - pageContent.globalStartIndex + (note.end - note.start)
            if insertIndex <= attributedString.length {
                attributedString.insert(noteIconAttributedString, at: insertIndex)
            } else {
                attributedString.append(noteIconAttributedString)
            }
        }

        DispatchQueue.main.async {
            self.textView.attributedText = attributedString
        }
    }

}

extension TextPageViewController {
    private func addBookmarkView() {
        guard let content = pageContentt else { return }
        removeBookmarkView()
        
        let bookmarkSize: CGFloat = 70
        let isBookmarked = BookmarkManager.shared.isBookmarked(
            bookId: bookChapterrs.first?.bookID ?? 0,
            chapterNumber: content.chapterNumber,
            pageNumberInChapter: content.pageNumberInChapter
        )
        
        let bookmarkView = BookmarkView(
            frame: CGRect(x: 0, y: 0, width: bookmarkSize, height: bookmarkSize),
            isBookmarked: isBookmarked,
            isHalfFilled: false // Optionally track this if you re-add it to your Bookmark model
        )
        bookmarkView.delegate = self
        bookmarkView.tag = 999
        view.addSubview(bookmarkView)
        self.bookmarkView = bookmarkView
    }

    private func removeBookmarkView() {
        view.subviews.first { $0.tag == 999 }?.removeFromSuperview()
    }

    @objc private func bookmarkUpdated(_ notification: Notification) {
        guard let updatedPage = notification.object as? (bookId: Int, chapterNumber: Int, pageNumberInChapter: Int),
              updatedPage.bookId ==  bookChapterrs.first?.bookID ?? 0,
              updatedPage.chapterNumber == pageContentt?.chapterNumber,
              updatedPage.pageNumberInChapter == pageContentt?.pageNumberInChapter else { return }
        refreshBookmarkUI()
    }

    func didToggleBookmark() {
        toggleBookmark()
    }

    @objc private func toggleBookmark() {
        guard let content = pageContentt else { return }

        let isBookmarked = BookmarkManager.shared.isBookmarked(
            bookId:  bookChapterrs.first?.bookID ?? 0,
            chapterNumber: content.chapterNumber,
            pageNumberInChapter: content.pageNumberInChapter
        )

        if isBookmarked {
            BookmarkManager.shared.removeBookmark(
                bookId:  bookChapterrs.first?.bookID ?? 0,
                chapterNumber: content.chapterNumber,
                pageNumberInChapter: content.pageNumberInChapter
            )
            print("❌ Bookmark removed for Book ID \( bookChapterrs.first?.bookID ?? 0), Chapter \(content.chapterNumber), Page \(content.pageNumberInChapter)")
        } else {
            let bookmark = Bookmark(
                serverId: nil,
                id: Int64(UUID().uuidString.hashValue), // or another ID generator
                bookId:  bookChapterrs.first?.bookID ?? 0,
                chapterNumber: content.chapterNumber,
                pageNumberInChapter: content.pageNumberInChapter,
                pageNumberInBook: content.pageNumberInBook,
                text: "", // optional custom note
                lastUpdated: Date() // convert to `Instant` equivalent if needed
            )
            BookmarkManager.shared.saveBookmark(bookmark)
            print("✅ Bookmark added for Book ID \( bookChapterrs.first?.bookID ?? 0), Page \(content.pageNumberInBook)")
        }

        NotificationCenter.default.post(
            name: Notification.Name("BookmarkUpdated"),
            object: (
                bookId:  bookChapterrs.first?.bookID ?? 0,
                chapterNumber: content.chapterNumber,
                pageNumberInChapter: content.pageNumberInChapter
            )
        )

        refreshBookmarkUI()
    }

    @objc private func refreshBookmarkUI() {
        guard let content = pageContentt else { return }
        let isBookmarked = BookmarkManager.shared.isBookmarked(
            bookId:  bookChapterrs.first?.bookID ?? 0,
            chapterNumber: content.chapterNumber,
            pageNumberInChapter: content.pageNumberInChapter
        )
        bookmarkView?.updateUI(isBookmarked: isBookmarked, isHalfFilled: false)
    }
}

extension  TextPageViewController {
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to: size, with: coordinator)

            guard let windowScene = view.window?.windowScene else {
                print("❌ No window scene found.")
                return
            }
            let newOrientation = windowScene.interfaceOrientation
            print("🔄 Detected Rotation in TextPageViewController: New Orientation = \(newOrientation.rawValue)")
            if let pageController = pageController, pageController.isRotationLocked, let lockedOrientation = pageController.lockedOrientation {
                print("🔒 Rotation is LOCKED in `PagedTextViewController` to: \(lockedOrientation.rawValue)")
            } else {
                print("🔄 Rotation is UNLOCKED: Device can rotate freely.")
            }
        }
}
extension TextPageViewController {

    func textView(_ textView: UITextView,
                  shouldInteractWith URL: URL,
                  in characterRange: NSRange,
                  interaction: UITextItemInteraction) -> Bool {
        
        let urlString = URL.absoluteString

        // 🔗 Internal link handler
        if urlString.starts(with: "internal:") {
            let key = urlString.replacingOccurrences(of: "internal:", with: "")
            print("✅ Internal link tapped: \(key)")
            handleInternalLinkClick(id: key)
            return false
        }

        // 📝 Note link handler
        if urlString.starts(with: "note:") {
            let noteIdString = urlString.replacingOccurrences(of: "note:", with: "")
            if let noteId = Int64(noteIdString) {
                print("📝 Note link tapped with note ID: \(noteId)")
                showNoteForNoteId(noteId)
            } else {
                print("⚠️ Invalid note ID in link: \(noteIdString)")
            }
            return false
        }

        // 📚 Reference link handler
        if urlString.starts(with: "reference:") {
            let id = urlString.replacingOccurrences(of: "reference:", with: "")
            print("📚 Reference link tapped with ID: \(id)")
            openReference(id) // Call your custom reference handler here
            return false
        }

        // 🌐 Let http/https links open normally
        return true
    }
    
    func openReference(_ id: String) {
        guard let referenceText = getReferenceContentById(id) else {
            print("⚠️ Reference not found for id: \(id)")
            return
        }

        let referenceVC = ReferenceBottomSheetViewController(nibName: "ReferenceBottomSheetViewController", bundle: nil)
        referenceVC.referenceID = id
        referenceVC.referenceText = referenceText

        if let sheet = referenceVC.sheetPresentationController {
            if #available(iOS 16.0, *) {
                let customDetent = UISheetPresentationController.Detent.custom(identifier: .init("small")) { context in
                    return 200 // desired height in points
                }
                sheet.detents = [customDetent]
            } else {
                sheet.detents = [.medium()] // fallback
            }

            sheet.prefersGrabberVisible = false
            sheet.preferredCornerRadius = 16
        }


        referenceVC.modalPresentationStyle = .pageSheet

        // Find topmost presenter
        if let topController = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController {
            
            var presenter = topController
            while let presented = presenter.presentedViewController {
                presenter = presented
            }

            presenter.present(referenceVC, animated: true)
        }
    }


    func getReferenceContentById(_ id: String) -> String? {
        if let data = UserDefaults.standard.data(forKey: "referenceList"),
           let references = try? JSONDecoder().decode([Reference].self, from: data) {
            print("📥 Loaded reference list from UserDefaults: \(references)")
            return references.first(where: { $0.id == id })?.text
        } else {
            print("⚠️ No reference list found in UserDefaults.")
            return nil
        }
    }


       func textView(_ textView: UITextView,
                     shouldInteractWith textAttachment: NSTextAttachment,
                     in characterRange: NSRange,
                     interaction: UITextItemInteraction) -> Bool {
           return false
       }

       func textView(_ textView: UITextView,
                     shouldInteractWith link: URL,
                     in characterRange: NSRange) -> Bool {
           return false
       }
    // 👉 Handle Tap Based on InternalLinkID
    func textView(_ textView: UITextView, didTapIn characterRange: NSRange) {
        guard let attributedText = textView.attributedText else { return }
        
        let attributes = attributedText.attributes(at: characterRange.location, effectiveRange: nil)
        
        if let internalLinkID = attributes[NSAttributedString.Key("InternalLinkID")] as? String {
            print("✅ Internal Link tapped with key: \(internalLinkID)")
            self.handleInternalLinkClick(id: internalLinkID)
        }
    }
    
    @objc private func handleTapOnTextView(_ recognizer: UITapGestureRecognizer) {
        let layoutManager = textView.layoutManager
        var location = recognizer.location(in: textView)
        location.x -= textView.textContainerInset.left
        location.y -= textView.textContainerInset.top
        
        let characterIndex = layoutManager.characterIndex(
            for: location,
            in: textView.textContainer,
            fractionOfDistanceBetweenInsertionPoints: nil
        )
        
        if characterIndex < textView.textStorage.length {
            let attributes = textView.attributedText.attributes(at: characterIndex, effectiveRange: nil)
            if let internalLinkID = attributes[NSAttributedString.Key("InternalLinkID")] as? String {
                print("✅ Internal Link tapped with key: \(internalLinkID)")
                self.handleInternalLinkClick(id: internalLinkID)
            }
        }
    }

    private func handleInternalLinkClick(id: String) {
        print("📩 handleInternalLinkClick triggered for key: \(id)")
        
        guard let savedData = UserDefaults.standard.data(forKey: "PageReferencesKey"),
              let savedPageReferences = try? JSONDecoder().decode([PageReference].self, from: savedData),
              let target = savedPageReferences.first(where: { $0.key == id }) else {
            print("❌ Target link not found in UserDefaults")
            return
        }

        let targetChapterNumber = target.chapterNumber
        let targetPageNumber = target.pageNumber
        let targetIndex = target.index

        print("🔵 Target → Chapter: \(targetChapterNumber), Page: \(targetPageNumber), Index: \(targetIndex)")

        guard let pageController = self.pageController else {
            print("❌ pageController is nil")
            return
        }

        // ✅ 1. Try exact match first (index match is most accurate)
        if let exactMatch = chunkedPages.firstIndex(where: {
            $0.chapterNumber == targetChapterNumber &&
            $0.pageNumberInChapter   == targetPageNumber - 1 &&
            $0.globalStartIndex <= targetIndex &&
            targetIndex < $0.globalEndIndex
        }) {
            let chunk = chunkedPages[exactMatch]
            print("✅ Exact match at index: \(exactMatch)")
            print("📌\(exactMatch) Chapter : \(chunkedPages[exactMatch].chapterNumber), Page: \(chunkedPages[exactMatch].pageNumberInChapter), globalStartIndex: \(chunkedPages[exactMatch].globalStartIndex)")
            print("📌\(exactMatch - 1) Chapter: \(chunkedPages[exactMatch - 1].chapterNumber), Page: \(chunkedPages[exactMatch - 1 ].pageNumberInChapter), globalStartIndex: \(chunkedPages[exactMatch - 1].globalStartIndex )")
            print("📌\(exactMatch - 2) Chapter: \(chunkedPages[exactMatch - 2].chapterNumber ), Page: \(chunkedPages[exactMatch - 2].pageNumberInChapter), globalStartIndex: \(chunkedPages[exactMatch - 2].globalStartIndex)" )
            navigateToPage(index: exactMatch)
            return
        }

        // 🔄 2. Fallback: Try matching by page number in chapter only (less accurate)
        if let fallbackIndex = chunkedPages.firstIndex(where: {
            $0.chapterNumber == targetChapterNumber &&
            $0.pageNumberInChapter == targetPageNumber
        }) {
            let chunk = chunkedPages[fallbackIndex]
            print("🔄 Fallback match at index: \(fallbackIndex)")
            print("📌 Chapter: \(chunk.chapterNumber), Page: \(chunk.pageNumberInChapter), globalStartIndex: \(chunk.globalStartIndex)")
            navigateToPage(index: fallbackIndex)
            return
        }

        print("❌ No matching chunk found for internal link id: \(id)")
    }


    private func navigateToPage(index: Int) {
        print("index : \(index)")
        guard let pageController = self.pageController,
              let targetVC = pageController.getViewController(at: index ) else {
            print("❌ Could not get view controller at index \(index)")
            return
        }

        pageController.currentIndex = index
        self.pageIndex = index

        pageController.pageViewController?.setViewControllers(
            [targetVC],
            direction: .forward,
            animated: false,
            completion: { _ in
                print("✅ Navigated to internal link target page.")
            }
        )

        if let delegate = internalLinkDelegate {
            delegate.didNavigateToInternalLink(pageIndex: index)
        } else {
            print("❌ Delegate is nil")
        }
    }

}

extension TextPageViewController {
    func highlightSearchResults() {
        guard !searchResults.isEmpty else { return }
        textView.textStorage.beginEditing()
        let fullRange = NSRange(location: 0, length: textView.textStorage.length)
        textView.textStorage.removeAttribute(.backgroundColor, range: fullRange)
        for result in searchResults {
            let content = result.content.lowercased()
            let fullText = textView.text.lowercased()
            if let range = fullText.range(of: content) {
                let nsRange = NSRange(range, in: fullText)
                textView.textStorage.addAttribute(.backgroundColor, value: UIColor.lightGray, range: nsRange)
            }
        }
        textView.textStorage.endEditing()
    }
}
