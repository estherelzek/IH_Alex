//
//  Extensions.swift
//  IH_Alex
//
//  Created by esterelzek on 17/02/2025.
//

import Foundation
import Foundation
import UIKit

class Decryptor {
    
    let IMAGE_SPLITTER = "!@D%#^$@@#BFSA#$"
    let IMAGE_NAME_SPLITTER = "!@D%#^$#BFSA#$"

    func decryption(txt: String, id: Int) -> String {
        print("decryption is called")
        let contents = txt.split(separator: IMAGE_NAME_SPLITTER)
        var decryptionTxt = ""
        print("contents[i] = \(contents.count)")
        for i in stride(from: 0, to: contents.count, by: 2) {
            decryptionTxt += decrypt(text: String(contents[i]))
            if i < contents.count - 1 {
                decryptionTxt += String(contents[i + 1]) // image
            }
        }
       // print("decryptionTxt: \(decryptionTxt)")
        return decryptionTxt
    }

    private func decrypt(text: String) -> String {
        var decryptedText = ""
        print("decrypt is called text size = \(text.count)")
        for scalar in text.unicodeScalars {
            let decryptedScalar = UnicodeScalar(scalar.value - 5) ?? scalar
            decryptedText.append(Character(decryptedScalar))
        }
        return decryptedText
    }
    
    static func isArabic(text: String) -> Bool {
       let arabicRange = text.range(of: "\\p{Arabic}", options: .regularExpression)
       return arabicRange != nil
   }
}

// MARK: - Convert UIColor to Hex
extension UIColor {
    func toHexString() -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let rgb = (Int(red * 255) << 16) | (Int(green * 255) << 8) | Int(blue * 255)
        return String(format: "#%06x", rgb)
    }
    
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexSanitized.hasPrefix("#") {
            hexSanitized.remove(at: hexSanitized.startIndex)
        }
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255.0,
            green: CGFloat((rgb >> 8) & 0xFF) / 255.0,
            blue: CGFloat(rgb & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
}
extension UserDefaults {
    
    func setColor(_ color: UIColor, forKey key: String) {
        let data = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
        set(data, forKey: key)
    }

    func color(forKey key: String) -> UIColor? {
        guard let data = data(forKey: key),
              let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data)
        else { return nil }
        return color
    }
}
extension UIColor {
    func isSimilar(to color: UIColor, tolerance: CGFloat = 0.05) -> Bool {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        return abs(r1 - r2) < tolerance &&
               abs(g1 - g2) < tolerance &&
               abs(b1 - b2) < tolerance &&
               abs(a1 - a2) < tolerance
    }
}
extension TextPageViewController {
    func setupCustomMenu() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(showTextOptionsAlert(_:)))
        textView.addGestureRecognizer(longPressGesture)
        textView.isUserInteractionEnabled = true
        textView.isEditable = false
        textView.isSelectable = true
    }
    
    @objc func showTextOptionsAlert(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let menuVC = CustomMenuViewController()
        menuVC.modalPresentationStyle = .overCurrentContext
        menuVC.modalTransitionStyle = .crossDissolve
        menuVC.delegate = self
        if let selectedRange = textView.selectedTextRange {
            let selectionRect = textView.firstRect(for: selectedRange) // Get bounding rect
            let convertedRect = textView.convert(selectionRect, to: view) // Convert to screen coordinates
            let menuHeight: CGFloat = 50
            let yOffset = max(convertedRect.minY - menuHeight - 10, view.safeAreaInsets.top + 10)
            menuVC.selectedTextFrame = CGRect(x: convertedRect.midX, y: yOffset, width: convertedRect.width, height: convertedRect.height)
        }
        present(menuVC, animated: true)
    }

//    @objc func showTextOptionsAlert(_ gesture: UILongPressGestureRecognizer) {
//        guard gesture.state == .began else { return }
//
//        let alertController = UIAlertController(title: "Options", message: "Choose an action", preferredStyle: .actionSheet)
//
//        alertController.addAction(UIAlertAction(title: "📋 Copy", style: .default) { _ in
//            self.copySelectedText()
//        })
//
//        alertController.addAction(UIAlertAction(title: "📤 Share", style: .default) { _ in
//            self.shareSelectedText()
//        })
//
//        alertController.addAction(UIAlertAction(title: "📝 Add Note", style: .default) { _ in
//            self.addNote()
//        })
//
//        let highlightAlert = UIAlertController(title: "Highlight", message: "Choose a highlight color", preferredStyle: .actionSheet)
//        
//        let colors: [(String, UIColor, String)] = [
//            ("Yellow", .yellow, "🟡"),
//            ("Blue", .blue, "🔵"),
//            ("Green", .green, "🟢"),
//            ("Red", .red, "🔴") // Fixed the emoji
//        ]
//
//        for (title, color, icon) in colors {
//            highlightAlert.addAction(UIAlertAction(title: "\(icon) \(title)", style: .default) { _ in
//                self.applyHighlight(color: color)
//            })
//        }
//
//        highlightAlert.addAction(UIAlertAction(title: "❌ Clear Highlight", style: .destructive) { _ in
//            self.clearHighlight()
//        })
//
//        highlightAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
//
//        alertController.addAction(UIAlertAction(title: "🎨 Highlight", style: .default) { _ in
//            self.present(highlightAlert, animated: true)
//        })
//
//        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
//        present(alertController, animated: true)
//    }
}

extension TextPageViewController {
    func getNSRange(from textRange: UITextRange) -> NSRange? {
        let location = textView.offset(from: textView.beginningOfDocument, to: textRange.start)
        let length = textView.offset(from: textRange.start, to: textRange.end)
        return NSRange(location: location, length: length)
    }
    
    func createColorImage(color: UIColor) -> UIImage? {
        let size = CGSize(width: 20, height: 20)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        color.setFill()
        context?.fillEllipse(in: CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
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

    
     func setupMenuButton() {
        menuButton = UIButton(type: .system)
        menuButton.setTitle("⋮", for: .normal)
        menuButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        menuButton.tintColor = .red
        menuButton.translatesAutoresizingMaskIntoConstraints = false // ✅ Use Auto Layout
        menuButton.addTarget(self, action: #selector(toggleMenu), for: .touchUpInside)
        
        view.addSubview(menuButton)
        NSLayoutConstraint.activate([
            menuButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            menuButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            menuButton.widthAnchor.constraint(equalToConstant: 40),
            menuButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
          func calculateHeight() -> CGFloat {
              let width = UIScreen.main.bounds.width - 40
              let targetSize = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
              let estimatedSize = textView.sizeThatFits(targetSize)
              return estimatedSize.height
          }

    func applyLanguageBasedAlignment(to attributedText: NSAttributedString) -> NSAttributedString {
        let mutableAttributedText = NSMutableAttributedString(attributedString: attributedText)
        mutableAttributedText.enumerateAttributes(in: NSRange(location: 0, length: mutableAttributedText.length), options: []) { attributes, range, _ in
            if attributes[.paragraphStyle] == nil {
                let textSegment = (mutableAttributedText.string as NSString).substring(with: range)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = isArabic(text: textSegment) ? .right : .left
                mutableAttributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
            }
        }
        return mutableAttributedText
    }
    
    func isArabic(text: String) -> Bool {
       let arabicRange = text.range(of: "\\p{Arabic}", options: .regularExpression)
       return arabicRange != nil
   }
}
