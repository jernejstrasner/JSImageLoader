//
//  NSDate+Equatable.swift
//  JSImageLoader
//
//  Created by Jernej Strasner on 6/25/14.
//
//

import Foundation

extension NSDate: Equatable {}

public func > (a: NSDate, b: NSDate) -> Bool {
	return a.compare(b) == NSComparisonResult.OrderedDescending
}

public func == (a: NSDate, b: NSDate) -> Bool {
	return a.compare(b) == NSComparisonResult.OrderedSame
}

public func < (a: NSDate, b: NSDate) -> Bool {
	return a.compare(b) == NSComparisonResult.OrderedAscending
}