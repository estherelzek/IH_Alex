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
    weak var delegate: NoteViewControllerDelegate?
    var isEdit: Bool = false

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
        guard let page = pageIndex, let range = noteRange else { return }
        var notes = NoteManager.shared.loadNotes()
        notes.removeAll { $0.page == page && $0.range == range }
        NoteManager.shared.saveAllNotes(notes)
        delegate?.didDeleteNote()
        dismissSelf()
    }

    @IBAction func saveNoteTapped(_ sender: Any) {
        guard let page = pageIndex, let range = noteRange else { return }
        var notes = NoteManager.shared.loadNotes()
        if let existingIndex = notes.firstIndex(where: { $0.page == page && $0.range == range }) {
            notes[existingIndex].content = noteText.text
        } else {
            let note = Note(page: page, range: range, title: noteTitle.text ?? "", content: noteText.text)
            notes.append(note)
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
        delegate?.reloadPageContent() // Reload content after dismissing
    }
    @objc private func handleOutsideTap(_ gesture: UITapGestureRecognizer) {
        let touchPoint = gesture.location(in: view)
        if !contentView.frame.contains(touchPoint) {
            dismissSelf()
        }
    }
}
