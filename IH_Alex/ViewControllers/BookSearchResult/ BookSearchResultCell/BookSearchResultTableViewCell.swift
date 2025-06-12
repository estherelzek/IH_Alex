//
//  BookSearchResultTableViewCell.swift
//  IH_Alex
//
//  Created by Esther Elzek on 05/05/2025.
//

import UIKit

class BookSearchResultTableViewCell: UITableViewCell {

    @IBOutlet weak var pageNumberLabel: UILabel!
    @IBOutlet weak var contentSearchLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
}
