//
//  Reading.swift
//  IH_Alex
//
//  Created by esterelzek on 19/02/2025.
//

import Foundation

func readFromBundleFile(fileName: String, fileExtension: String) {
    guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
        print("❌ File not found in bundle: \(fileName).\(fileExtension)")
        return
    }

    do {
        let fileContents = try String(contentsOf: fileURL, encoding: .utf8)
        print("📖 File content:\n\(fileContents)")
    } catch {
        print("❌ Error reading file: \(error.localizedDescription)")
    }
}

