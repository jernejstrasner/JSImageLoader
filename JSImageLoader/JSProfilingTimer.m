//
//  JSProfilingTimer.m
//  JSImageLoader
//
//  Created by Jernej Strasner on 1/30/14.
//
//

#import "JSProfilingTimer.h"

js_timer_t JSProfilingTimerStart(void) {
	struct timeval time;
	gettimeofday(&time, NULL);
	return time;
}

float JSProfilingTimerEnd(js_timer_t start) {
	struct timeval time;
	gettimeofday(&time, NULL);
	return time.tv_sec - start.tv_sec + 1e-6 * (time.tv_usec - start.tv_usec);
}