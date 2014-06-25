//
//  ImageLoaderCache.swift
//  JSImageLoader
//
//  Created by Jernej Strasner on 6/24/14.
//
//

import UIKit

class ImageLoaderCache {
	class var sharedCache: ImageLoaderCache {
		struct Singleton {
			static let instance = ImageLoaderCache()
		}
		return Singleton.instance
	}
	
	var cacheSize = 1024*1024*10 // Bytes
	
	// Private
	let cacheQueue = dispatch_queue_create("com.jernejstrasner.imageloader.cache", DISPATCH_QUEUE_CONCURRENT)
	let cleaningQueue = dispatch_queue_create("com.jernejstrasner.imageloader.cleaning", DISPATCH_QUEUE_SERIAL)
	
	init() {
		NSNotificationCenter.defaultCenter().addObserver(
			self,
			selector: "cleanupCache",
			name: UIApplicationDidEnterBackgroundNotification,
			object: nil
		)
	}
	
	func cacheImage(image: UIImage, url: NSURL) {
		dispatch_async(cacheQueue) {
			let imageData = self.dataFromImage(image)
			if (!imageData) {
				Logger.error("Could not get a data representation of the image!")
			}
			else {
				let urlString = url.absoluteString
				
			}
		}
	}
	
	func dataFromImage(image: UIImage!) -> NSData! {
		return UIImagePNGRepresentation(image)
	}
	
	func imageFromData(data: NSData!) -> UIImage! {
		return UIImage(data: data)
	}
}
