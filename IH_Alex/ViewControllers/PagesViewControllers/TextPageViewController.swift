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
    var currentFontSize: CGFloat = 8
    var pageContent: PageContent?
    var pageIndex: Int = 0
    let textView = UITextView()
    var bookmarkView: BookmarkView?
    var pageController: PagedTextViewController?
    var menuVC: MenuViewController?
    var lastBrightnessUpdate: TimeInterval = 0
    var isRotationLocked = false
    var lockedOrientation: UIInterfaceOrientation?
    var noteVC: NoteViewController?
    weak var delegate: MenuViewDelegate?
    var pages: [PageContent] = []
    var originalPages: [OriginalPage] = []
    weak var pageNavigationDelegate: PageNavigationDelegate?
    weak var internalLinkDelegate: InternalLinkNavigationDelegate?
    var searchKeyword: String?
    var searchResults: [SearchResult] = []

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextView()
        setupCustomMenu()
        if let pageContent = pageContent {
            loadHighlights(for: pageContent)
        } else {
            print("❌ No page content available — cannot load highlights.")
        }
        print("pageContent?.originalPageIndex : \(String(describing: pageContent?.originalPageIndex))")
        applySavedAppearance()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.loadNoteIcons()
            self.addBookmarkView()
        }
        setupMenuButton()
        setUpBritness()
        restoreBrightness()
        NotificationCenter.default.addObserver(self, selector: #selector(bookmarkUpdated(_:)), name: Notification.Name("BookmarkUpdated"), object: nil)
      
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
        if let attributedContent = pageContent?.attributedText {
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addBookmarkView()
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
        print("📍 pages count: \(pages.count)")

        guard pages.indices.contains(pageIndex) else {
            print("📍 Invalid pageIndex: \(pageIndex), out of bounds.")
            preservedAbsoluteLocation = 0
            return
        }

        let currentPage = pages[pageIndex]
        let previousOriginalPagesLength = originalPages
            .prefix(while: { $0.index < currentPage.originalPageIndex })
            .map { $0.fullAttributedText.length }
            .reduce(0, +)

        preservedAbsoluteLocation = previousOriginalPagesLength + currentPage.rangeInOriginal.location
        print("📍 Preserved absolute location: \(preservedAbsoluteLocation) for current visible page \(pageIndex)")
        let finalFontSize = UserDefaults.standard.float(forKey: "globalFontSize")
        let screenSize = view.bounds.inset(by: UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)).size
        let spacingEnabled = UserDefaults.standard.bool(forKey: "globalLineSpacing")
        let lineSpacing: CGFloat = spacingEnabled ? 8.0 : 0.0

        self.pageController?.rebuildPages(
            fontSize: CGFloat(finalFontSize),
            screenSize: screenSize
        )

       refreshContent()
       reloadPageContent()
       
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
               print("🔹 Font size unchanged. Skipping update.")
               return
           }
           UserDefaults.standard.set(finalFontSize, forKey: "globalFontSize")
           UserDefaults.standard.synchronize()
           print("✅ Saved finalFontSize: \(finalFontSize)")
           applyFontSize(finalFontSize)
           pageController?.applyFontSizeToAllPages(finalFontSize)
           loadNoteIcons()
       }
    
    func refreshContent() {
        guard let pageController = self.pageController else { return }
        let latestContent = pageController.pages[pageIndex]
        pageContent = latestContent
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
            print("🔄 Reloading content for page \(pageIndex)")
        if let pageContent = pageContent {
            loadHighlights(for: pageContent)
        } else {
            print("❌ No page content available — cannot load highlights.")
        }

            applySavedAppearance()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.loadNoteIcons() // ✅ Ensure icons appear
            self.addBookmarkView()
        }
    }
    
    func reloadContent(at index: Int) {
        guard pages.indices.contains(index) else {
            print("❌ Index \(index) out of bounds. Cannot reload.")
            return
        }
        pageIndex = index
        guard let pageController = self.pageController else { return }
        let latestContent = pageController.pages[pageIndex]
        print("pageIndex: \(pageIndex)")
        print("pageIndex content: \(pages[pageIndex].attributedText)")

        pageContent = latestContent
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
              let pageContent = pageContent else { return }

        let nsRange = getNSRange(from: selectedRange) ?? NSRange(location: 0, length: 0)

        let globalRange = NSRange(
            location: pageContent.globalStartIndex + nsRange.location,
            length: nsRange.length
        )

        let noteVC = NoteViewController(nibName: "NoteViewController", bundle: nil)
        noteVC.noteTitleContent = selectedText
        noteVC.noteTextContent = ""
        noteVC.noteRange = globalRange
        noteVC.delegate = self // Page index no longer needed here
        noteVC.view.frame = CGRect(x: -10, y: -10, width: view.frame.width - 80, height: view.frame.height - 80)
        noteVC.view.center = view.center
        addChild(noteVC)
        view.addSubview(noteVC.view)
        noteVC.didMove(toParent: self)
        self.noteVC = noteVC
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
        textView.subviews.forEach { subview in
            if subview is UIImageView { subview.removeFromSuperview() }
        }

        guard let pageContent = pageContent else { return }

        let notes = NoteManager.shared.loadNotes().filter { note in
            let noteRange = note.range.location..<(note.range.location + note.range.length)
            let pageRange = pageContent.globalStartIndex..<pageContent.globalEndIndex
            return noteRange.overlaps(pageRange)
        }

        for note in notes {
            let localLocation = note.range.location - pageContent.globalStartIndex
            guard localLocation >= 0 else { continue }

            let startOffset = localLocation
            let endOffset = startOffset + note.range.length

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
                noteIcon.tag = note.range.location
                textView.addSubview(noteIcon)
            }
        }
    }


    @objc func noteIconTapped(_ sender: UITapGestureRecognizer) {
        if let tappedIcon = sender.view as? UIImageView {
            let noteLocation = tappedIcon.tag
            showNoteForLocation(noteLocation)
        }
    }

    func showNoteForLocation(_ location: Int) {
        let allNotes = NoteManager.shared.loadNotes()
        guard let pageContent = pageContent else { return }

        let pageRange = pageContent.globalStartIndex..<pageContent.globalEndIndex
        let matchingNote = allNotes.first {
            $0.range.location == location &&
            pageRange.contains($0.range.location)
        }

        if let note = matchingNote {
            let noteVC = NoteViewController(nibName: "NoteViewController", bundle: nil)
            noteVC.noteTitleContent = note.title
            noteVC.noteTextContent = note.content
            noteVC.noteRange = note.range
            noteVC.delegate = self
            noteVC.isEdit = true
            noteVC.view.frame = CGRect(x: -10 , y: -10, width: view.frame.width - 60, height: view.frame.height - 80)
            noteVC.view.center = view.center
            addChild(noteVC)
            view.addSubview(noteVC.view)
            noteVC.didMove(toParent: self)
            self.noteVC = noteVC
        }
    }

    
    func textViewDidChange(_ textView: UITextView) {
        loadNoteIcons()
    }
    func applyHighlight(color: UIColor) {
        guard let selectedRange = textView.selectedTextRange, let text = textView.text(in: selectedRange) else {
            print("No text selected")
            return
        }

        let nsRange = getNSRange(from: selectedRange) ?? NSRange(location: 0, length: 0)
        let hexColor = color.toHexString()
        guard let currentPageContent = getCurrentPageContent() else {
            print("Current page content not found")
            return
        }
        let globalRange = calculateGlobalRange(from: nsRange, pageContent: currentPageContent)
        let highlight = Highlight(range: nsRange, page: pageIndex, globalRange: globalRange, color: hexColor)
        HighlightManager.shared.saveHighlight(highlight)
        print("highlight saved: \(highlight)")
        updateTextViewHighlight(range: nsRange, color: color)
    }

    func calculateGlobalRange(from nsRange: NSRange, pageContent: PageContent) -> NSRange {
        let globalStart = nsRange.location + pageContent.globalStartIndex
        let globalEnd = globalStart + nsRange.length
        
        return NSRange(location: globalStart, length: globalEnd - globalStart)
    }

    func updateTextViewHighlight(range: NSRange, color: UIColor) {
        textView.textStorage.beginEditing()
        textView.textStorage.addAttribute(.backgroundColor, value: color, range: range)
        textView.textStorage.endEditing()
    }
    func getCurrentPageContent() -> PageContent? {
        return pages.first { $0.pageIndexInBook == pageIndex }
    }

    func clearHighlight() {
        guard let selectedRange = textView.selectedTextRange else { return }
        let nsRange = getNSRange(from: selectedRange) ?? NSRange(location: 0, length: 0)
        var highlights = HighlightManager.shared.loadHighlights()
        highlights.removeAll { highlight in
            NSIntersectionRange(highlight.range, nsRange).length > 0 && highlight.page == pageIndex
        }
        HighlightManager.shared.saveAllHighlights(highlights)
        refreshTextViewHighlights()
    }

    func refreshTextViewHighlights() {
        let attributedString = NSMutableAttributedString(attributedString: textView.attributedText)
        let fullRange = NSRange(location: 0, length: attributedString.length)
        attributedString.removeAttribute(.backgroundColor, range: fullRange)
        let highlights = HighlightManager.shared.loadHighlights().filter { $0.page == pageIndex }

        for highlight in highlights {
            if highlight.range.location + highlight.range.length <= attributedString.length {
                attributedString.addAttribute(.backgroundColor, value: UIColor(hex: highlight.color), range: highlight.range)
            }
        }
        
        DispatchQueue.main.async {
            self.textView.attributedText = attributedString
        }
    }

    func loadHighlights(for pageContent: PageContent) {
        // Load main highlights from HighlightManager
        let highlights = HighlightManager.shared.loadHighlights()
        let pageGlobalRange = NSRange(location: pageContent.globalStartIndex, length: pageContent.globalEndIndex - pageContent.globalStartIndex)
        
        // 🔍 Filter only the highlights that belong to the current page
        let filteredHighlights = highlights.filter { highlight in
            let highlightRange = highlight.globalRange.location..<(highlight.globalRange.location + highlight.globalRange.length)
            let pageRange = pageContent.globalStartIndex..<pageContent.globalEndIndex
            return highlightRange.overlaps(pageRange)
        }
        
        print("📌 Highlights for this page: \(filteredHighlights)")
        
        textView.textStorage.beginEditing()
        
        // 🧽 Clear previous highlights (both main and search-based)
        let fullRange = NSRange(location: 0, length: textView.textStorage.length)
        textView.textStorage.removeAttribute(.backgroundColor, range: fullRange)

        // 🌟 Apply Main Highlights
        for highlight in filteredHighlights {
            let localLocation = highlight.globalRange.location - pageContent.globalStartIndex
            let localRange = NSRange(location: localLocation, length: highlight.globalRange.length)
            if localRange.location >= 0 && localRange.location + localRange.length <= textView.textStorage.length {
                textView.textStorage.addAttribute(.backgroundColor, value: UIColor(hex: highlight.color), range: localRange)
            } else {
                print("⚠️ Skipping out-of-bounds highlight: \(highlight)")
            }
        }

        // 🌟 Apply Temporary Search Highlights (if any)
        if !searchResults.isEmpty {
            let fullText = textView.text.lowercased()
            
            for searchResult in searchResults {
                let searchText = searchResult.content.lowercased()
                var searchRange = fullText.startIndex..<fullText.endIndex
                
                while let range = fullText.range(of: searchText, options: [], range: searchRange) {
                    let nsRange = NSRange(range, in: fullText)
                    textView.textStorage.addAttribute(.backgroundColor, value: UIColor.systemCyan.withAlphaComponent(0.2), range: nsRange)
                    searchRange = range.upperBound..<searchRange.upperBound
                }
            }
        }
        
        textView.textStorage.endEditing()
    }





    func deleteNoteForLocation(_ location: Int) {
        var notes = NoteManager.shared.loadNotes().filter { $0.page == pageIndex }
        notes.removeAll { $0.range.location == location }
        
        var allNotes = NoteManager.shared.loadNotes()
        allNotes.removeAll { $0.page == pageIndex && $0.range.location == location }
        
        NoteManager.shared.saveAllNotes(allNotes)
        
        DispatchQueue.main.async {
            self.refreshTextViewNotes()
            self.loadNoteIcons() // Important: remove the icons too
        }
    }


    func refreshTextViewNotes() {
        let attributedString = NSMutableAttributedString(attributedString: textView.attributedText)
        attributedString.enumerateAttribute(.link, in: NSRange(location: 0, length: attributedString.length)) { value, range, _ in
            if let link = value as? String, link.starts(with: "note:") {
                attributedString.removeAttribute(.link, range: range)
                attributedString.replaceCharacters(in: range, with: "") // Remove old attachment too
            }
        }
        
        let notes = NoteManager.shared.loadNotes().filter { $0.page == pageIndex }
        for note in notes {
            let noteAttachment = NSTextAttachment()
            noteAttachment.image = UIImage(systemName: "note.text")
            let noteString = NSAttributedString(attachment: noteAttachment)
            
            let noteIconAttributedString = NSMutableAttributedString(attributedString: noteString)
            noteIconAttributedString.addAttribute(.link, value: "note:\(note.range.location)", range: NSRange(location: 0, length: noteIconAttributedString.length))
            
            if note.range.location + note.range.length <= attributedString.length {
                attributedString.insert(noteIconAttributedString, at: note.range.location + note.range.length)
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
        let bookmarkedPages = BookmarkManager.shared.getAllBookmarkedPages()
        guard let originalPageIndex = pageContent?.originalPageIndex else { return }
        removeBookmarkView()
        let bookmarkSize: CGFloat = 70
        let isBookmarked = BookmarkManager.shared.isBookmarked(originalPageIndex: originalPageIndex)
        let isHalfFilled = BookmarkManager.shared.isHalfFilled(originalPageIndex: originalPageIndex)
        let bookmarkView = BookmarkView(
            frame: CGRect(x: 0, y: 0, width: bookmarkSize, height: bookmarkSize),
            isBookmarked: isBookmarked,
            isHalfFilled: isHalfFilled
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
        guard let updatedOriginalPage = notification.object as? Int,
              updatedOriginalPage == pageContent?.originalPageIndex else { return }
        refreshBookmarkUI()
    }

    func didToggleBookmark() {
        toggleBookmark()
    }

    @objc private func toggleBookmark() {
        guard let originalPageIndex = pageContent?.originalPageIndex else { return }
        let isBookmarked = BookmarkManager.shared.isBookmarked(originalPageIndex: originalPageIndex)
        if isBookmarked {
            BookmarkManager.shared.removeBookmark(forOriginalPage: originalPageIndex)
            print("❌ Bookmark removed for original page: \(originalPageIndex)")
        } else {
            let bookmark = Bookmark(originalPageIndex: originalPageIndex, isHalfFilled: true)
            BookmarkManager.shared.saveBookmark(bookmark)
            print("✅ Bookmark added for original page: \(originalPageIndex)")
        }

        NotificationCenter.default.post(name: Notification.Name("BookmarkUpdated"), object: originalPageIndex)
        refreshBookmarkUI()
    }
    @objc private func refreshBookmarkUI() {
        guard let originalPageIndex = pageContent?.originalPageIndex else { return }
        let isBookmarked = BookmarkManager.shared.isBookmarked(originalPageIndex: originalPageIndex)
        let isHalfFilled = BookmarkManager.shared.isHalfFilled(originalPageIndex: originalPageIndex)
        bookmarkView?.updateUI(isBookmarked: isBookmarked, isHalfFilled: isHalfFilled)
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

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        let urlString = URL.absoluteString
        
        if urlString.starts(with: "internal:") {
            let key = urlString.replacingOccurrences(of: "internal:", with: "")
            print("✅ Internal link tapped: \(key)")
            handleInternalLinkClick(id: key)
            return false
        } else if urlString.starts(with: "note:") {
            if let location = Int(urlString.replacingOccurrences(of: "note:", with: "")) {
                print("📝 Note link tapped at location: \(location)")
                showNoteForLocation(location)
            }
            return false
        }
        
        return true // allow normal http/https links
    }


       
       func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
           return false
       }

    func textView(_ textView: UITextView, shouldInteractWith link: URL, in characterRange: NSRange) -> Bool {
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
        if let savedData = UserDefaults.standard.data(forKey: "PageReferencesKey"),
           let savedPageReferences = try? JSONDecoder().decode([PageReference].self, from: savedData) {
            print("🔵 savedPageReferences \(savedPageReferences)")
            
            // 👉 Find the target link by ID
            if let target = savedPageReferences.first(where: { $0.key == id }) {
                print("🔵 Found target page: Chapter \(target.chapterNumber), Page \(target.pageNumber) in Chapter")

                guard let pageController = self.pageController else { return }

                // 🔍 **PRINT THE FULL STRUCTURE OF PAGES FOR THE TARGET CHAPTER**
                print("🔍 Full structure of pages for Chapter \(target.chapterNumber):")
                var foundPageInChapter = false
                pages.forEach { page in
                    if page.chapterNumber == target.chapterNumber {
                        foundPageInChapter = true
                        print("➡️ Chapter: \(page.chapterNumber), Page In Chapter: \(page.pageNumberInChapter)")
                    }
                }
                
                print("🔍 pages \(pages):")
                if !foundPageInChapter {
                    print("❌ No pages found for Chapter \(target.chapterNumber)")
                }

                // 👉 Find the actual page chunk in `pages`
                if let realPageIndex = pages.firstIndex(where: {
                    $0.chapterNumber == target.chapterNumber && $0.pageNumberInChapter == target.pageNumber
                }) {
                    pageController.currentIndex = realPageIndex
                    self.pageIndex = realPageIndex

                    if let targetVC = pageController.getViewController(at: realPageIndex) {
                        pageController.pageViewController.setViewControllers(
                            [targetVC],
                            direction: .forward,
                            animated: false,
                            completion: { finished in
                                print("✅ Navigated to internal link target page.")
                            }
                        )
                    }

                    if internalLinkDelegate == nil {
                        print("❌ Delegate is nil")
                    } else {
                        print("✅ Delegate is set")
                    }

                    // 👉 Notify the delegate (MainViewController) to update slider and labels
                    internalLinkDelegate?.didNavigateToInternalLink(pageIndex: realPageIndex)

                } else {
                    print("❌ Target page not found in allPages for Chapter \(target.chapterNumber) and Page \(target.pageNumber)")
                }

            } else {
                print("❌ Target link not found")
            }
        }
    }



}
extension TextPageViewController {
//    func highlightSearchResult(keyword: String) {
//        guard !keyword.isEmpty else { return }
//        
//        // Remove previous highlights
//        let fullRange = NSRange(location: 0, length: textView.attributedText.length)
//        let mutableAttributed = NSMutableAttributedString(attributedString: textView.attributedText)
//        mutableAttributed.removeAttribute(.backgroundColor, range: fullRange)
//        
//        // Find all occurrences of the search term
//        let string = textView.text.lowercased()
//        let lowercasedKeyword = keyword.lowercased()
//        var searchRange = NSRange(location: 0, length: string.utf16.count)
//        var ranges: [NSRange] = []
//
//        while searchRange.location < string.utf16.count {
//            let foundRange = (string as NSString).range(of: lowercasedKeyword, options: [], range: searchRange)
//            if foundRange.location != NSNotFound {
//                ranges.append(foundRange)
//                let newLocation = foundRange.location + foundRange.length
//                searchRange = NSRange(location: newLocation, length: string.utf16.count - newLocation)
//            } else {
//                break
//            }
//        }
//        
//        // Apply highlight color (Light Blue)
//        for range in ranges {
//            mutableAttributed.addAttribute(.backgroundColor, value: UIColor.systemBlue.withAlphaComponent(0.3), range: range)
//        }
//        
//        // Update the text view with highlighted text
//        textView.attributedText = mutableAttributed
//        
//        // Scroll to the first occurrence
//        if let firstRange = ranges.first {
//            textView.scrollRangeToVisible(firstRange)
//        }
//    }
    func highlightSearchResults() {
        // Make sure searchResults is not empty
        guard !searchResults.isEmpty else { return }

        textView.textStorage.beginEditing()

        // Remove any previous background color
        let fullRange = NSRange(location: 0, length: textView.textStorage.length)
        textView.textStorage.removeAttribute(.backgroundColor, range: fullRange)

        // Loop through each search result and highlight the keyword in the text
        for result in searchResults {
            let content = result.content.lowercased()
            let fullText = textView.text.lowercased()

            // Search for the keyword in the full text
            if let range = fullText.range(of: content) {
                let nsRange = NSRange(range, in: fullText)

                // Apply background color highlight
                textView.textStorage.addAttribute(.backgroundColor, value: UIColor.lightGray, range: nsRange)
            }
        }

        textView.textStorage.endEditing()
    }

}
