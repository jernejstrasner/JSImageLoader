//
//  ProfilingTimer.swift
//  JSImageLoader
//
//  Created by Jernej Strasner on 7/7/14.
//
//

import Foundation

class ProfilingTimer {
	
	var time = UnsafePointer<timeval>()

	init() {
		gettimeofday(time, nil)
	}
	
	func end() -> Float {
		var new_time = UnsafePointer<timeval>()
		gettimeofday(new_time, nil)
		let sec = Int(new_time.memory.tv_sec) - Int(time.memory.tv_sec)
		let usec = Int(new_time.memory.tv_usec) - Int(time.memory.tv_usec)
		return Float(sec) + Float(usec)*10e-6
	}
}
