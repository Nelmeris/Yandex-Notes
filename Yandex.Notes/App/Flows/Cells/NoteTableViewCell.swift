//
//  NoteTableViewCell.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 10/07/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import UIKit

class NoteTableViewCell: UITableViewCell {

    @IBOutlet weak var colorView: DesignableView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var destructionDateLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        colorView.backgroundColor = nil
    }

}
