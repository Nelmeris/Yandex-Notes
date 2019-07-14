//
//  GalleryPhotoViewCell.swift
//  Notes
//
//  Created by Artem Kufaev on 12/07/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import UIKit

class GalleryPhotoViewCell: UICollectionViewCell {
    
    @IBOutlet weak var photoView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        photoView.image = nil
    }
    
}
