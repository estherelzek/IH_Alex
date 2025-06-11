//
//  ReferenceBottomSheetViewController.swift
//  IH_Alex
//
//  Created by Esther Elzek on 11/06/2025.
//

import UIKit
import UIKit

class ReferenceBottomSheetViewController: UIViewController {

    @IBOutlet weak var titleReferenceLabel: UILabel!
    @IBOutlet weak var contentTextView: UITextView!
    
    var referenceID: String = ""
    var referenceText: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        titleReferenceLabel.text = "Reference [\(referenceID)]"
        contentTextView.text = referenceText
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
    }

    @IBAction func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }
}
