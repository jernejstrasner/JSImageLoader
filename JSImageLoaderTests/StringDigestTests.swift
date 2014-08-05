//
//  JSImageLoaderTests.swift
//  JSImageLoaderTests
//
//  Created by Jernej Strasner on 6/25/14.
//
//

import XCTest

class ExtensionTests: XCTestCase {
    
	func testMD5() {
		let string = "Testiram neki"
		let hash = "d4f117b9a61ce2541e179113c50fcb1a"
		
		XCTAssertEqual(hash, string.md5)
	}
	
	func testMD5Performance() {
		let strings = randomStringArray()
		measureBlock { () -> Void in
			for string in strings {
				string.md5
			}
		}
	}
	
	func testMD5Performance2() {
		let strings = randomStringArray()
		measureBlock { () -> Void in
			for string in strings {
				string.md5NSData
			}
		}
	}
	
	func testNSDateEquatable() {
		XCTAssertTrue(NSDate() < NSDate(timeIntervalSinceNow: 1))
		XCTAssertTrue(NSDate() > NSDate(timeIntervalSinceNow: -1))
		XCTAssertTrue(NSDate() == NSDate(timeIntervalSinceNow: 0))
	}
	
}

extension ExtensionTests {
	
	func randomStringArray() -> [String] {
		// Generate array of random strings
		var strings = [String]()
		for i in 0..<1000 {
			strings.append(NSUUID().UUIDString)
		}
		return strings
	}
	
}

extension String {
	
	var md5NSData: String! {
		let str = self.cStringUsingEncoding(NSUTF8StringEncoding)
			let strLen = CC_LONG(self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
			let digestLen = Int(CC_MD5_DIGEST_LENGTH)
			let data = NSMutableData(length: digestLen)
			let result = UnsafeMutablePointer<CUnsignedChar>(data.mutableBytes)
			
			CC_MD5(str!, strLen, result)
			
			let a = UnsafeBufferPointer<CUnsignedChar>(start: result, length: data.length)
			var hash = NSMutableString()
			
			for i in a {
				hash.appendFormat("%02x", i)
			}
			
			return String(format: hash)
	}
	
}