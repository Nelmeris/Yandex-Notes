//
//  GalleryViewerViewController.swift
//  Notes
//
//  Created by Artem Kufaev on 09/07/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import UIKit

class GalleryViewerViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    
    var images: [UIImage]!
    var selectImageId: Int!
    var imageViews = [UIImageView]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for image in images {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            scrollView.addSubview(imageView)
            imageViews.append(imageView)
        }
        
        self.view.backgroundColor = .black
        
        scrollView.bounces = false
        scrollView.isPagingEnabled = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let width = scrollView.frame.width
        for (index, imageView) in imageViews.enumerated() {
            imageView.frame.size = scrollView.frame.size
            imageView.frame.origin.x = width * CGFloat(index)
            imageView.frame.origin.y = 0
        }
        let contentWidth = scrollView.frame.width * CGFloat(imageViews.count)
        scrollView.contentSize = CGSize(width: contentWidth, height: scrollView.frame.height)
        scrollView.contentOffset = CGPoint(x: width * CGFloat(selectImageId), y: 0)
    }

}
