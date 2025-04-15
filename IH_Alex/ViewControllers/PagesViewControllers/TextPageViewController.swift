//
//  TextPageViewController.swift
//  IH_Alex
//
//  Created by esterelzek on 16/02/2025.
//
import UIKit


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
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextView()
       setupCustomMenu()
        loadHighlights()
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

    private func showMenu() {
        let menuVC = MenuViewController()
        menuVC.delegate = self
        menuVC.modalPresentationStyle = .overFullScreen // So the parent stays underneath
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
        print("📍 currentPage: \(currentPage)")
        let previousOriginalPagesLength = originalPages
            .prefix(while: { $0.index < currentPage.originalPageIndex })
            .map { $0.fullAttributedText.length }
            .reduce(0, +)

        preservedAbsoluteLocation = previousOriginalPagesLength + currentPage.rangeInOriginal.location
        print("📍 Preserved absolute location: \(preservedAbsoluteLocation) for current visible page \(pageIndex)")

        // Now rebuild pages as usual
        let finalFontSize = UserDefaults.standard.float(forKey: "globalFontSize")
        let screenSize = view.bounds.inset(by: UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)).size
        let spacingEnabled = UserDefaults.standard.bool(forKey: "globalLineSpacing")
        let lineSpacing: CGFloat = spacingEnabled ? 8.0 : 0.0

        self.pageController?.rebuildPages(
            fontSize: CGFloat(finalFontSize),
            screenSize: screenSize
           // preservedLocation: preservedAbsoluteLocation
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
           let step: CGFloat = 2.0
           guard let currentFont = textView.attributedText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont else {
               print("⚠️ No font found in attributed text!")
               return
           }
           let currentSize = currentFont.pointSize
           let newFontSize = increase ? currentSize + step : currentSize - step
           let finalFontSize = max(min(newFontSize, 50), 12)
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
            loadHighlights()
            applySavedAppearance()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.loadNoteIcons() // ✅ Ensure icons appear
            self.addBookmarkView()
        }
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
              let selectedText = textView.text(in: selectedRange) else { return }
        
        let nsRange = getNSRange(from: selectedRange) ?? NSRange(location: 0, length: 0)
        let noteVC = NoteViewController(nibName: "NoteViewController", bundle: nil)
        noteVC.noteTitleContent = ""  // New property for title
        noteVC.noteTextContent = ""   // Empty note initially
        noteVC.noteRange = nsRange
        noteVC.pageIndex = pageIndex
        noteVC.delegate = self
        noteVC.noteTitleContent = selectedText // Pass selected text
        noteVC.view.frame = CGRect(x: -10 , y: -10, width: view.frame.width - 80, height: view.frame.height - 80)
        noteVC.view.center = view.center
        addChild(noteVC)
        view.addSubview(noteVC.view)
        noteVC.didMove(toParent: self)
        self.noteVC = noteVC // Store reference if needed
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

        let notes = NoteManager.shared.loadNotes().filter { $0.page == pageIndex }
        for note in notes {
            let noteRange = NSRange(location: note.range.location, length: note.range.length)
            if let start = textView.position(from: textView.beginningOfDocument, offset: note.range.location),
               let end = textView.position(from: textView.beginningOfDocument, offset: note.range.location + note.range.length),
               let textRange = textView.textRange(from: start, to: end) {
                let textRect = textView.firstRect(for: textRange)
                let textViewFrame = textView.convert(textView.bounds, to: view) // Convert to main view
                let leftMargin = textViewFrame.minX + 0 // Adjust to stay near textView left edge
                let noteIcon = UIImageView(image: UIImage(systemName: "square.and.pencil"))
                noteIcon.tintColor = .systemBlue
                noteIcon.frame = CGRect(x: leftMargin, y: textRect.minY, width: 20, height: 20) // Left-aligned
                noteIcon.isUserInteractionEnabled = true
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(noteIconTapped(_:)))
                noteIcon.addGestureRecognizer(tapGesture)
                noteIcon.tag = note.range.location // Store note range location
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
        let savedNotes = NoteManager.shared.loadNotes().filter { $0.page == pageIndex }
        if let matchingNote = savedNotes.first(where: { $0.range.location == location }) {
            let noteVC = NoteViewController(nibName: "NoteViewController", bundle: nil)
            noteVC.noteTitleContent = matchingNote.title
            noteVC.noteTextContent = matchingNote.content
            noteVC.noteRange = matchingNote.range
            noteVC.pageIndex = pageIndex
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

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        let urlString = URL.absoluteString
        if urlString.starts(with: "note:") {
            if let location = Int(urlString.replacingOccurrences(of: "note:", with: "")) {
                showNoteForLocation(location)
            }
            return false
        }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        loadNoteIcons()
    }

    func applyHighlight(color: UIColor) {
        guard let selectedRange = textView.selectedTextRange, let text = textView.text(in: selectedRange) else { return }
        let nsRange = getNSRange(from: selectedRange) ?? NSRange(location: 0, length: 0)
        let highlight = Highlight(text: text, range: nsRange, color: color.toHexString(), page: pageIndex)
        HighlightManager.shared.saveHighlight(highlight)
        updateTextViewHighlight(range: nsRange, color: color)
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

    func updateTextViewHighlight(range: NSRange, color: UIColor) {
        let mutableAttributedText = NSMutableAttributedString(attributedString: textView.attributedText)
        if color == .clear {
            mutableAttributedText.removeAttribute(.backgroundColor, range: range)
        } else {
            mutableAttributedText.addAttribute(.backgroundColor, value: color, range: range)
        }
        textView.attributedText = mutableAttributedText
    }
    
    func loadHighlights() {
        let highlights = HighlightManager.shared.loadHighlights().filter { $0.page == pageIndex }
        let attributedString = NSMutableAttributedString(attributedString: textView.attributedText)
        for highlight in highlights {
            if highlight.range.location + highlight.range.length <= attributedString.length {
                attributedString.addAttribute(.backgroundColor, value: UIColor(hex: highlight.color), range: highlight.range)
            }
        }
        textView.attributedText = attributedString
    }

    func deleteNoteForLocation(_ location: Int) {
        var notes = NoteManager.shared.loadNotes()
        notes.removeAll { $0.page == pageIndex && $0.range.location == location }
        NoteManager.shared.saveAllNotes(notes)
        DispatchQueue.main.async {
            self.refreshTextViewNotes()
        }
    }

    func refreshTextViewNotes() {
        let attributedString = NSMutableAttributedString(attributedString: textView.attributedText)
        attributedString.enumerateAttribute(.link, in: NSRange(location: 0, length: attributedString.length)) { value, range, _ in
            if let link = value as? String, link.starts(with: "note:") {
                attributedString.deleteCharacters(in: range)
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
        removeBookmarkView()
        let bookmarkSize: CGFloat = 70
        let isBookmarked = BookmarkManager.shared.isBookmarked(page: pageIndex)
        let isHalfFilled = BookmarkManager.shared.isHalfFilled(page: pageIndex)
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
        guard let updatedPage = notification.object as? Int, updatedPage == pageIndex else { return }
        refreshBookmarkUI()
    }

    func didToggleBookmark() {
        toggleBookmark()
    }

    @objc private func toggleBookmark() {
        let isBookmarked = BookmarkManager.shared.isBookmarked(page: pageIndex)
        if isBookmarked {
            BookmarkManager.shared.removeBookmark(forPage: pageIndex)
        } else {
            let bookmark = Bookmark(page: pageIndex, isHalfFilled: true)
            BookmarkManager.shared.saveBookmark(bookmark)
        }
        NotificationCenter.default.post(name: Notification.Name("BookmarkUpdated"), object: pageIndex)
        refreshBookmarkUI()
    }

    @objc private func refreshBookmarkUI() {
        let isBookmarked = BookmarkManager.shared.isBookmarked(page: pageIndex)
        let isHalfFilled = BookmarkManager.shared.isHalfFilled(page: pageIndex)
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
