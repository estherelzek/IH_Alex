//
//  BookSearchResultTableViewCell.swift
//  IH_Alex
//
//  Created by Esther Elzek on 05/05/2025.
//

import UIKit

class BookSearchResultTableViewCell: UITableViewCell {

   // @IBOutlet weak var chapterNumberLabel: UILabel!
    @IBOutlet weak var pageNumberLabel: UILabel!
    @IBOutlet weak var contentSearchLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
