//
//  CustomMenuViewController.swift
//  IH_Alex
//
//  Created by Esther Elzek on 03/04/2025.
//
import UIKit

protocol CustomMenuDelegate: AnyObject {
    func copySelectedText()
    func shareSelectedText()
    func addNote()
    func applyHighlight(color: UIColor)
    func clearHighlight()
}

class CustomMenuViewController: UIViewController {

    @IBOutlet weak var contentViewMenu: UIView!
    @IBOutlet weak var stackContent: UIStackView!
    
    var selectedTextFrame: CGRect = .zero
    weak var delegate: CustomMenuDelegate?
    var menuPosition: CGPoint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleOutsideTap(_:)))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.1) // Semi-transparent background
        contentViewMenu.layer.cornerRadius = 12
        contentViewMenu.layer.masksToBounds = true
        setupMenuView()
    }
    
    @objc private func handleOutsideTap(_ gesture: UITapGestureRecognizer) {
        let touchPoint = gesture.location(in: view)
        if !contentViewMenu.frame.contains(touchPoint) {
            closeMenu()
        }
    }
    @IBAction func shareButtonTapped(_ sender: Any) {
        delegate?.shareSelectedText()
        dismiss(animated: true)
    }
    
    @IBAction func copyButtonTapped(_ sender: Any) {
        delegate?.copySelectedText()
        dismiss(animated: true)
    }
    
    @IBAction func noteButtonTappend(_ sender: Any) {
        delegate?.addNote()
        dismiss(animated: true)
    }

    @IBAction func pinkHighlit(_ sender: Any) {
        let customPink = UIColor(red: 243/255, green: 167/255, blue: 173/255, alpha: 1.0) // #F3A7AD
            delegate?.applyHighlight(color: customPink)
            dismiss(animated: true)
    }
    
    @IBAction func greenhighlit(_ sender: Any) {
        let customGreen = UIColor(red: 131/255, green: 223/255, blue: 117/255, alpha: 1.0) // #83DF75
            delegate?.applyHighlight(color: customGreen)
            dismiss(animated: true)
    }
    
    @IBAction func yellowHighlite(_ sender: Any) {
        let customYellow = UIColor(red: 255/255, green: 220/255, blue: 0/255, alpha: 1.0) // #FFDC00
            delegate?.applyHighlight(color: customYellow)
        dismiss(animated: true)
    }

    @IBAction func purpleHighlite(_ sender: Any) {
        let customPurple = UIColor(red: 216/255, green: 165/255, blue: 218/255, alpha: 1.0) // #D8A5DA
            delegate?.applyHighlight(color: customPurple)
        dismiss(animated: true)
    }

    @IBAction func dehighlite(_ sender: Any) {
        delegate?.clearHighlight()
        dismiss(animated: true)
    }
    
    private func closeMenu() {
        dismiss(animated: true)
    }
}

extension CustomMenuViewController {
    func setupMenuView() {
        guard let menuView = contentViewMenu, let stackView = stackContent else { return }
        menuView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.deactivate(menuView.constraints)
        NSLayoutConstraint.deactivate(stackView.constraints)

        let safeAreaTop = view.safeAreaInsets.top
        let safeAreaBottom = view.bounds.height - view.safeAreaInsets.bottom
        let screenWidth = view.bounds.width
        let buttonWidth: CGFloat = 60
        let buttonSpacing: CGFloat = 10
        let buttonCount = stackView.arrangedSubviews.count
        let requiredWidth = CGFloat(buttonCount) * buttonWidth + CGFloat(buttonCount - 1) * buttonSpacing
        let menuWidth = min(requiredWidth, screenWidth - 30)
        var menuX = selectedTextFrame.midX - (menuWidth / 2)
        menuX = max(10, min(menuX, screenWidth - menuWidth - 10))
        let menuHeight: CGFloat = 50
        let centeredY = selectedTextFrame.midY
        let adjustedY = max(min(centeredY, safeAreaBottom - menuHeight - 10), safeAreaTop + 10)
        NSLayoutConstraint.activate([
            menuView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: menuX),
            menuView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -10),
            menuView.topAnchor.constraint(equalTo: view.topAnchor, constant: adjustedY),
            menuView.widthAnchor.constraint(equalToConstant: menuWidth),
            menuView.heightAnchor.constraint(equalToConstant: menuHeight)
        ])
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: menuView.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: menuView.trailingAnchor, constant: -10),
            stackView.topAnchor.constraint(equalTo: menuView.topAnchor, constant: 5),
            stackView.bottomAnchor.constraint(equalTo: menuView.bottomAnchor, constant: -5)
        ])
    }
}

