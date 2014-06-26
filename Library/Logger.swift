//
//  Logger.swift
//  JSImageLoader
//
//  Created by Jernej Strasner on 6/26/14.
//
//

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
