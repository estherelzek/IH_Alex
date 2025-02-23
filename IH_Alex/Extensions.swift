//
//  Extensions.swift
//  IH_Alex
//
//  Created by esterelzek on 17/02/2025.
//

import Foundation
import Foundation

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
        print("decryptionTxt: \(decryptionTxt)")
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

}


