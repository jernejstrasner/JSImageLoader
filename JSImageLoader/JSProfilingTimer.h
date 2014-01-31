//
//  JSProfilingTimer.h
//  JSImageLoader
//
//  Created by Jernej Strasner on 1/30/14.
//
//

#import <Foundation/Foundation.h>
#import <sys/time.h>

typedef struct timeval js_timer_t;

js_timer_t JSProfilingTimerStart();
float JSProfilingTimerEnd(js_timer_t start);