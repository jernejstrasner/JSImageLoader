//
//  ImageCell.swift
//  JSImageLoader
//
//  Created by Jernej Strasner on 6/27/14.
//
//

import UIKit

class ImageCell: UICollectionViewCell {
	
	@IBOutlet var imageView: UIImageView
	
	var imageURL: NSURL? {
	didSet {
		if imageURL {
			ImageLoader.sharedLoader.getImageAtURL(imageURL!) { error, image, url, cached in
				if self.imageURL?.isEqual(url) {
					self.imageView.image = image
				}
			}
		}
	}
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		
		imageView.image = nil
		imageURL = nil
	}
}
