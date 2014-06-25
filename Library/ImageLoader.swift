//
//  ImageLoader.swift
//  JSImageLoader
//
//  Created by Jernej Strasner on 6/24/14.
//
//

import UIKit

let NumberOfRetries = 2
let MaxDownloadConnections = 3

class Logger {
	
	class func log(message: String) {
		println("[JSImageLoader] "+message)
	}
	
	class func info(message: String) {
		self.log("[INFO] "+message)
	}
	
	class func warning(message: String) {
		self.log("[WARNING] "+message)
	}
	
	class func error(message: String) {
		self.log("[ERROR] "+message)
	}
	
}

class ImageLoader {
	class var sharedLoader: ImageLoader {
		struct Singleton {
			static let instance = ImageLoader()
		}
		return Singleton.instance
	}
	
	var cacheSize: UInt = 1024*1024*10 // In bytes
	
	// Private
	let downloadQueue = NSOperationQueue()
	
	init() {
		downloadQueue.maxConcurrentOperationCount = MaxDownloadConnections
	}
	
	deinit {
		downloadQueue.cancelAllOperations()
	}
	
	// Actions
	
	func suspend() {
		downloadQueue.suspended = true
	}
	
	func resume() {
		downloadQueue.suspended = false
	}
	
	func cancel() {
		downloadQueue.cancelAllOperations()
	}
	
	func getImageAtURL(url: NSURL, completion: (error: NSError!, image: UIImage!, url: NSURL, cached: Bool) -> Void) {
		ImageLoaderCache.sharedCache.fetchImage(url) { image in
			
			if image {
				completion(error: nil, image: image, url: url, cached: true)
			}
			else {
				self.downloadQueue.addOperationWithBlock() {
					let request = NSURLRequest(URL: url)
					var response: NSURLResponse?
					var netError: NSError? = nil
					
					var counter = NumberOfRetries
					while counter-- > 0 {
						let imageData = NSURLConnection.sendSynchronousRequest(request,
							returningResponse: &response,
							error: &netError)
						
						if netError {
							switch netError!.code {
							case NSURLErrorUnsupportedURL, NSURLErrorBadURL, NSURLErrorBadServerResponse, NSURLErrorRedirectToNonExistentLocation, NSURLErrorFileDoesNotExist, NSURLErrorFileIsDirectory:
								completion(error: netError, image: nil, url: url, cached: false)
								return
							default:
								if counter < 1 {
									completion(error: netError, image: nil, url: url, cached: false)
									return
								}
							}
						}
						else {
							let loadedImage = UIImage(data: imageData)
							ImageLoaderCache.sharedCache.cacheImage(loadedImage, url: url)
							completion(error: nil, image: loadedImage, url: url, cached: false)
							return
						}
					}
				}
			}
		}
	}
}