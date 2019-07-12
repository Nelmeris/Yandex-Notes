//
//  GalleryPhotoViewCell.swift
//  Notes
//
//  Created by Артем Куфаев on 12/07/2019.
//  Copyright © 2019 Артем Куфаев. All rights reserved.
//

import UIKit

class GalleryPhotoViewCell: UICollectionViewCell {
    
    @IBOutlet weak var photoView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        photoView.image = nil
    }
    
}
