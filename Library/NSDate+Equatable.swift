//
//  NSDate+Equatable.swift
//  JSImageLoader
//
//  Created by Jernej Strasner on 6/25/14.
//
//

import Foundation

extension NSDate: Equatable {}

func > (a: NSDate, b: NSDate) -> Bool {
	return a.compare(b) == NSComparisonResult.OrderedDescending
}

func == (a: NSDate, b: NSDate) -> Bool {
	return a.compare(b) == NSComparisonResult.OrderedSame
}

func < (a: NSDate, b: NSDate) -> Bool {
	return a.compare(b) == NSComparisonResult.OrderedAscending
}