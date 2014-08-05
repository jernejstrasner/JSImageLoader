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
	var backgroundTaskID = UIBackgroundTaskInvalid
	
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
	
	func fetchImage(url: NSURL, completion: (UIImage!) -> Void) {
		dispatch_async(cacheQueue) {
			let urlString = url.absoluteString
			let hash = urlString.md5
			
			var image: UIImage! = nil
			if let path = self.cachePath() {
				let imageData = NSData(contentsOfFile: path.stringByAppendingPathComponent(hash))
				if imageData.length > 0 {
					image = self.imageFromData(imageData)
					if image {
						// Update modified date, to keep cache from deleting it too early
						let imageFileURL = NSURL(fileURLWithPath: path)
						var error: NSError?
						imageFileURL.setResourceValue(NSDate(), forKey: NSURLContentModificationDateKey, error: &error)
						if error != nil {
							Logger.warning("The last modified date could not be updated for image: \(error!.localizedDescription)")
						}
					}
				}
			}
			
			dispatch_async(dispatch_get_main_queue()) {
				completion(image)
			}
		}
	}
	
	func cleanupCache() {
		
		struct FileMetadata {
			var fileURL: NSURL
			var fileSize: Int
			var date: NSDate
		}
		
		backgroundTaskID = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler() {
			UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskID)
			self.backgroundTaskID = UIBackgroundTaskInvalid
		}
		
		dispatch_async(cleaningQueue) {
			let fm = NSFileManager.defaultManager()
			var cacheSize = 0
			var files = [FileMetadata]()
			let fileKeys = [NSURLContentModificationDateKey, NSURLTotalFileAllocatedSizeKey]
			let dirEnumerator = fm.enumeratorAtURL(NSURL(fileURLWithPath: self.cachePath()),
				includingPropertiesForKeys: fileKeys,
				options: nil,
				errorHandler: nil)
			
			while let fileURL = dirEnumerator.nextObject() as? NSURL {
				if let metadata = fileURL.resourceValuesForKeys(fileKeys, error: nil) {
					let key = NSURLTotalFileAllocatedSizeKey as String
					let fileSize = (metadata[key] as NSNumber).unsignedIntegerValue
					cacheSize += fileSize
					files.append(FileMetadata(fileURL: fileURL, fileSize: fileSize, date: metadata[NSURLContentModificationDateKey] as NSDate))
				}
			}
			
			if cacheSize > self.cacheSize {
				let targetSize = self.cacheSize*2/3
				
				files.sort() { (a: FileMetadata, b: FileMetadata) in a.date < b.date }
				
				for fd: FileMetadata in files {
					if fm.removeItemAtURL(fd.fileURL, error: nil) {
						cacheSize -= fd.fileSize
						if cacheSize <= targetSize {
							break
						}
					}
				}
			}
			
			UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskID)
			self.backgroundTaskID = UIBackgroundTaskInvalid
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
