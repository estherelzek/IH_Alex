//
//  NoteViewController.swift
//  IH_Alex
//
//  Created by Esther Elzek on 05/03/2025.
//

import UIKit

protocol NoteViewControllerDelegate: AnyObject {
    func didSaveNote()
    func didDeleteNote()
    func reloadPageContent()
}

class NoteViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var noteText: UITextView!
    @IBOutlet weak var buttonsStack: UIStackView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var noteTitle: UILabel!
    
    @IBOutlet weak var contentView: UIView!
    var noteTextContent: String = ""
    var noteTitleContent: String?
    var noteRange: NSRange?
    var pageIndex: Int?
    var originalPageIndex: Int?
    var originalPageBody: String?
    var bookId: Int?
    var bookChapterrs: [Chapterr] = []
    var pagess: [Page] = []
    var chunkedPages: [Chunk] = []
    var pageContentt: Chunk?
    var noteId: Int64?
    weak var delegate: NoteViewControllerDelegate?
    var isEdit: Bool = false
    var globalNoteRange: NSRange?
    var currentChapterNumber: Int?
    var currentPageNumberInBook: Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        noteText.text = noteTextContent
        noteTitle.text = noteTitleContent ?? "New Note"
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleOutsideTap(_:)))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        containerView.layer.cornerRadius = 10
        containerView.layer.masksToBounds = true
        noteText.layer.cornerRadius = 10
        noteText.layer.borderWidth = 1
        noteText.layer.borderColor = UIColor.lightGray.cgColor
        deleteButton.isHidden = !isEdit
        scrollView.backgroundColor = .clear
        scrollView.isOpaque = false
        containerView.backgroundColor = .clear
    }

    @IBAction func closeButtonTapped(_ sender: Any) {
        dismissSelf()
    }

    @IBAction func deleteNoteTapped(_ sender: Any) {
        guard let noteId = noteId else { return }
        var notes = NoteManager.shared.loadNotes()
        notes.removeAll { $0.id == noteId }
        NoteManager.shared.saveAllNotes(notes)
        delegate?.didDeleteNote()
        dismissSelf()
    }

    @IBAction func saveNoteTapped(_ sender: Any) {
        guard let bookId = bookId else {
            print("❌ Missing bookId")
            return
        }

        guard let pageContentt = pageContentt else {
            print("❌ Missing page content")
            return
        }

        let chapterNumber = pageContentt.chapterNumber
        let pageNumberInChapter = pageContentt.pageNumberInChapter
        let pageNumberInBook = pageContentt.pageNumberInBook

        guard let noteRange = noteRange else {
            print("❌ Missing local note range")
            return
        }

        let start = noteRange.location
        let end = start + noteRange.length
        let noteContent = noteText.text ?? ""
        noteTextContent = noteContent ?? ""
        var notes = NoteManager.shared.loadNotes()
        if let noteId = noteId, let existingIndex = notes.firstIndex(where: { $0.id == noteId }) {
            notes[existingIndex].noteText = noteContent
            notes[existingIndex].selectedNoteText = noteTextContent
            notes[existingIndex].lastUpdated = Date()
            notes[existingIndex] = notes[existingIndex].withUpdatedRange(start: start, end: end)
        } else {
            let newNote = Note(
                id: Int64(Date().timeIntervalSince1970 * 1000),
                bookId: self.bookId ?? 0,
                chapterNumber: chapterNumber,
                pageNumberInChapter: pageNumberInChapter,
                pageNumberInBook: pageNumberInBook,
                start: start,
                end: end,
                noteText: noteContent,
                selectedNoteText: noteTitleContent ?? "",
                lastUpdated: Date()
            )
            notes.append(newNote)
            self.noteId = newNote.id
        }
        NoteManager.shared.saveAllNotes(notes)
        delegate?.didSaveNote()
        dismissSelf()
    }

    private func dismissSelf() {
        if let backgroundView = parent?.view.viewWithTag(999) {
            backgroundView.removeFromSuperview()
        }
        self.view.removeFromSuperview()
        self.removeFromParent()
        delegate?.reloadPageContent()
    }
    
    @objc private func handleOutsideTap(_ gesture: UITapGestureRecognizer) {
        let touchPoint = gesture.location(in: view)
        if !contentView.frame.contains(touchPoint) {
            dismissSelf()
        }
    }
}
