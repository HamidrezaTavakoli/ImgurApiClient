//
//  ImageCollectionViewCell.swift
//  ImgurApiClient
//
//  Created by Hamid on 2/21/18.
//  Copyright © 2018 PicBlast. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    // MARK: - Constants
    private struct Constants {
        static let CornerRadiusForCell: CGFloat = 5.0
    }
    
    // MARK: Model
    var image: UIImage? {didSet { updateUI() } }
    
    // MARK: IBOutlets
    @IBOutlet weak var imageView: UIImageView! {
        didSet {
            imageView.contentMode = .scaleAspectFill
            updateUI()
        }
    }
}

// MARK: Helper Functions
extension ImageCollectionViewCell {
    private func updateUI() {
        contentView.layer.cornerRadius = Constants.CornerRadiusForCell
        contentView.clipsToBounds = true
        imageView?.image = image
    }
}
