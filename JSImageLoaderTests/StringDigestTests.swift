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
	
	func testNSDateEquatable() {
		XCTAssertTrue(NSDate() < NSDate(timeIntervalSinceNow: 1))
		XCTAssertTrue(NSDate() > NSDate(timeIntervalSinceNow: -1))
		XCTAssertTrue(NSDate() == NSDate(timeIntervalSinceNow: 0))
	}
	
}
