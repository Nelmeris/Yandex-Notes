//
//  NoteTableViewCell.swift
//  Notes
//
//  Created by Артем Куфаев on 10/07/2019.
//  Copyright © 2019 Артем Куфаев. All rights reserved.
//

import UIKit

class NoteTableViewCell: UITableViewCell {

    @IBOutlet weak var colorView: DesignableView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        colorView.backgroundColor = nil
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        colorView.backgroundColor = nil
    }

}
