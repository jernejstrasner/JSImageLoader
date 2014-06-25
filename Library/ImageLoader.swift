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
	
	func getImageAtURL(url: NSURL, completion: (error: NSError, image: UIImage, url: NSURL, cached: Bool)) {
		
	}
}