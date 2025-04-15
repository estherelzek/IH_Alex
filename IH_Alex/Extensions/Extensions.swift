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
    
//    convenience init(hex: String) {
//        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
//        if hexSanitized.hasPrefix("#") {
//            hexSanitized.remove(at: hexSanitized.startIndex)
//        }
//        
//        var rgb: UInt64 = 0
//        Scanner(string: hexSanitized).scanHexInt64(&rgb)
//        self.init(
//            red: CGFloat((rgb >> 16) & 0xFF) / 255.0,
//            green: CGFloat((rgb >> 8) & 0xFF) / 255.0,
//            blue: CGFloat(rgb & 0xFF) / 255.0,
//            alpha: 1.0
//        )
//    }
}

//extension UIColor {
//    convenience init(hex: String) {
//        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
//        if hexSanitized.hasPrefix("#") {
//            hexSanitized = String(hexSanitized.dropFirst())
//        }
//        
//        var rgb: UInt64 = 0
//        Scanner(string: hexSanitized).scanHexInt64(&rgb)
//        
//        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
//        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
//        let blue = CGFloat(rgb & 0x0000FF) / 255.0
//        
//        self.init(red: red, green: green, blue: blue, alpha: 1.0)
//    }
//}
extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexSanitized.hasPrefix("#") {
            hexSanitized = String(hexSanitized.dropFirst())
        }
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

extension UserDefaults {
    
//    func setColor(_ color: UIColor, forKey key: String) {
//        let data = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
//        set(data, forKey: key)
//    }
//
//    func color(forKey key: String) -> UIColor? {
//        guard let data = data(forKey: key),
//              let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data)
//        else { return nil }
//        return color
//    }
}

extension UIColor {
    func components() -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if self.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return (r, g, b, a)
        }
        return nil
    }

//    func isSimilar(to color: UIColor, tolerance: CGFloat) -> Bool {
//        guard let components1 = self.components(), let components2 = color.components() else { return false }
//        
//        let rDiff = abs(components1.r - components2.r)
//        let gDiff = abs(components1.g - components2.g)
//        let bDiff = abs(components1.b - components2.b)
//        
//        // If the RGB differences are within the tolerance, consider the colors similar
//        return rDiff <= tolerance && gDiff <= tolerance && bDiff <= tolerance
//    }
}
extension UserDefaults {
    func setColor(_ color: UIColor, forKey key: String) {
        let colorData = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
        set(colorData, forKey: key)
    }

    func color(forKey key: String) -> UIColor? {
        guard let colorData = data(forKey: key),
              let color = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? UIColor else {
            return nil
        }
        return color
    }
}
extension UIColor {
    func toRGB() -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if self.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return (r, g, b, a)
        }
        return nil
    }

    func isSimilar(to color: UIColor, tolerance: CGFloat = 0.1) -> Bool {
        guard let color1 = self.toRGB(), let color2 = color.toRGB() else {
            return false
        }

        // Compare the RGB components with tolerance
        let redDiff = abs(color1.r - color2.r)
        let greenDiff = abs(color1.g - color2.g)
        let blueDiff = abs(color1.b - color2.b)

        return redDiff < tolerance && greenDiff < tolerance && blueDiff < tolerance
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
extension Notification.Name {
    static let didCloseMenuAndRequestRefresh = Notification.Name("didCloseMenuAndRequestRefresh")
}
extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
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
