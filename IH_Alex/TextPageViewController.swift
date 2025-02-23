//
//  TextPageViewController.swift
//  IH_Alex
//
//  Created by esterelzek on 16/02/2025.
//
import UIKit

class TextPageViewController: UIViewController, UITextViewDelegate {
    var pageContent: PageContent?
    var pageIndex: Int = 0
    let textView = UITextView()
    var pageController: PagedTextViewController? // Reference to UIPageViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextView()
//        DispatchQueue.main.async {
//            self.restoreHighlightedRanges() // ✅ Ensure highlights are reapplied
//        }
        let highlightItem = UIMenuItem(title: "Highlight", action: #selector(highlightSelectedText))
        UIMenuController.shared.menuItems = [highlightItem]
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(highlightSelectedText) {
            return textView.selectedRange.length > 0
        }
        return super.canPerformAction(action, withSender: sender)
    }


    func setupTextView() {
           textView.isEditable = false
           textView.isSelectable = true
           textView.isUserInteractionEnabled = true
           textView.attributedText = pageContent?.attributedText
           textView.dataDetectorTypes = [] // Disable automatic detection
           textView.delegate = self // ✅ Enable link handling
           textView.translatesAutoresizingMaskIntoConstraints = false
           textView.font = UIFont.systemFont(ofSize: 18)
           textView.backgroundColor = .white
           view.addSubview(textView)
           NSLayoutConstraint.activate([
               textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
               textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
               textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
               textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
           ])
       }
    
    func getNSRange(from textRange: UITextRange) -> NSRange? {
        guard let start = textView.position(from: textView.beginningOfDocument, offset: 0),
              let end = textView.position(from: start, offset: textView.offset(from: textView.beginningOfDocument, to: textRange.end))
        else { return nil }
        let location = textView.offset(from: textView.beginningOfDocument, to: textRange.start)
        let length = textView.offset(from: textRange.start, to: textRange.end)

        return NSRange(location: location, length: length)
    }

    /// ✅ Called when user selects "Highlight"
    @objc func highlightSelectedText() {
        guard let selectedRange = textView.selectedTextRange else { return }
        let nsRange = getNSRange(from: selectedRange)
        if let range = nsRange {
            toggleHighlight(range)
        }
    }
    
    func toggleHighlight(_ range: NSRange) {
        guard let originalText = textView.attributedText else { return }
        let mutableAttributedText = NSMutableAttributedString(attributedString: originalText)
        let attributes = mutableAttributedText.attributes(at: range.location, effectiveRange: nil)
        if attributes[.backgroundColor] != nil {
            mutableAttributedText.removeAttribute(.backgroundColor, range: range)
            removeHighlightedRange(range)
        } else {
            mutableAttributedText.addAttributes([
                .backgroundColor: UIColor.yellow
            ], range: range)
            saveHighlightedRange(range)
        }
        let selectedRange = textView.selectedRange  // ✅ Save selection
        textView.attributedText = mutableAttributedText
        textView.selectedRange = selectedRange      // ✅ Restore selection
    }
    
    func saveHighlightedRange(_ range: NSRange) {
        var highlightedRanges = UserDefaults.standard.array(forKey: "highlightedRanges") as? [[Int]] ?? []

        let rangeArray = [range.location, range.length]
        print("Saving highlight:", rangeArray) // ✅ Debugging line

        if !highlightedRanges.contains(where: { $0[0] == range.location && $0[1] == range.length }) {
            highlightedRanges.append(rangeArray)
            UserDefaults.standard.set(highlightedRanges, forKey: "highlightedRanges")
            UserDefaults.standard.synchronize()
        }
    }

    func restoreHighlightedRanges() {
        guard let savedRanges = UserDefaults.standard.array(forKey: "highlightedRanges") as? [[Int]],
              let originalText = textView.attributedText else { return }
        print("Restoring highlights:", savedRanges) // ✅ Debugging line
        let mutableAttributedText = NSMutableAttributedString(attributedString: originalText)
        for rangeArray in savedRanges {
            if rangeArray.count == 2 {
                let range = NSRange(location: rangeArray[0], length: rangeArray[1])
                if range.location + range.length <= mutableAttributedText.length {
                    mutableAttributedText.addAttributes([.backgroundColor: UIColor.yellow], range: range)
                }
            }
        }
        textView.attributedText = mutableAttributedText
    }
    /// ✅ Remove highlighted range from UserDefaults
    func removeHighlightedRange(_ range: NSRange) {
        var highlightedRanges = UserDefaults.standard.array(forKey: "highlightedRanges") as? [[Int]] ?? []
        if let index = highlightedRanges.firstIndex(where: { $0[0] == range.location && $0[1] == range.length }) {
            highlightedRanges.remove(at: index)
            UserDefaults.standard.set(highlightedRanges, forKey: "highlightedRanges")
            UserDefaults.standard.synchronize() // ✅ Ensure removal is saved
        }
    }
   
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        let urlString = URL.absoluteString

        if urlString.hasPrefix("navigateTo:") {
            let mention = urlString.replacingOccurrences(of: "navigateTo:", with: "")

            if mention == "@Swift" {
                let targetIndex = 2
                pageController?.navigateToPage(targetIndex) // ✅ Reuse existing instance
            }
            return false
        }
        return true
    }
    
}
