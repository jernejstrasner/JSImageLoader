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
		// TODO: write profiling
		dispatch_async(cacheQueue) {
			let imageData = self.dataFromImage(image)
			if (!imageData) {
				Logger.error("Could not get a data representation of the image!")
			}
			else {
				let urlString = url.absoluteString
				let hash = urlString.md5
				
				if let path = self.cachePath() {
					imageData.writeToFile(path.stringByAppendingPathComponent(hash), atomically: true)
				}
				else {
					Logger.error("Could not write image to cache because a path does not exist!")
				}
			}
		}
	}
	
	func dataFromImage(image: UIImage!) -> NSData! {
		return UIImagePNGRepresentation(image)
	}
	
	func imageFromData(data: NSData!) -> UIImage! {
		return UIImage(data: data)
	}
	
	func cachePath() -> String! {
		let searchPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)
		if searchPaths.count == 0 {
			return nil
		}
		
		let cachePath = searchPaths[0].stringByAppendingPathComponent("com.jernejstrasner.jsimageloader.images")
		
		let fm = NSFileManager.defaultManager()
		var isDir: ObjCBool = false
		let fileExists = fm.fileExistsAtPath(cachePath, isDirectory: &isDir)
		
		if fileExists && !Bool(isDir) {
			let res = fm.removeItemAtPath(cachePath, error: nil)
			if !res {
				Logger.error("A file already exists and could not be deleted: \(cachePath)")
				return nil
			}
		}
		else if !fileExists {
			let res = fm.createDirectoryAtPath(cachePath, withIntermediateDirectories: true, attributes: nil, error: nil)
			if !res {
				Logger.error("Cache directory could not be created at: \(cachePath)")
				return nil
			}
		}
		
		return cachePath
	}
}
