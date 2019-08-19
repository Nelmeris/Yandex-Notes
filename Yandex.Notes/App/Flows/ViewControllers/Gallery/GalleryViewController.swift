//
//  GalleryViewController.swift
//  Notes
//
//  Created by Artem Kufaev on 12/07/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import UIKit

private let reuseIdentifier = "PhotoCell"

class GalleryViewController: UICollectionViewController {
    
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout!
    var images = [UIImage]()
    
    let storyboardId = "Main"
    let vcId = "GalleryViewer"
    
    let imagePicker = UIImagePickerController()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        for index in 1...5 {
            let photo = UIImage(named: "Photo\(index)")!
            images.append(photo)
        }
        let photo = UIImage(named: "Icon")!
        images.append(photo)

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewPhoto))
        
        imagePicker.delegate = self
    }
    
    @objc func addNewPhoto() {
        self.present(imagePicker, animated: true, completion: nil)
    }

}

// MARK: - UICollectionViewDelegate
extension GalleryViewController {
    
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
}

// MARK: - UIImagePickerControllerDelegate
extension GalleryViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        images.append(pickedImage)
        self.collectionView.insertItems(at: [IndexPath(row: images.count - 1, section: 0)])
        self.dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - UICollectionViewDelegateFlowLayout
extension GalleryViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = collectionView.bounds.size
        let currentSize = size.width > size.height ? size.height : size.width
        return CGSize(width: currentSize / 3.2, height: currentSize / 3.2)
    }
    
}

// MARK: - UICollectionViewDataSource
extension GalleryViewController {

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: reuseIdentifier,
            for: indexPath) as? GalleryPhotoViewCell
            ?? GalleryPhotoViewCell()
        
        cell.photoView.image = images[indexPath.row]
    
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: storyboardId, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: vcId) as! GalleryViewerViewController
        vc.images = images
        vc.selectImageId = indexPath.row
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}
