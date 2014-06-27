//
//  String+MD5.swift
//  JSImageLoader
//
//  Created by Jernej Strasner on 6/25/14.
//
//

import Foundation

extension String {
	
	var md5: String! {
		let str = self.cStringUsingEncoding(NSUTF8StringEncoding)
		let strLen = UInt32(self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
		let digestLen = Int(CC_MD5_DIGEST_LENGTH)
		let result = UnsafePointer<CUnsignedChar>.alloc(digestLen)
		
		CC_MD5(str!, strLen, result)
		
		var hash = NSMutableString()
		for i in 0..digestLen {
			hash.appendFormat("%02x", result[i])
		}
		
		result.destroy()
		
		return String(hash)
	}
	
}
