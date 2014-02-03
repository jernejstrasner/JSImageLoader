/*
 Copyright (c) 2011 Jernej Strasner
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software
 and associated documentation files (the "Software"), to deal in the Software without restriction,
 including without limitation the rights to use, copy, modify, merge, publish, distribute,
 sublicense, and/or sell copies of the Software, and to permit persons to whom the Software
 is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or
 substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
 PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
 FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 
 */
//
//  CachedImageLoader.h
//  JSImageCache
//
//  Created by Jernej Strasner on 5/23/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#define LOGGING 1

#define JSILLogA(format, ...)		NSLog((@"[JSIMAGELOADER] " format), ##__VA_ARGS__);

#if LOGGING
#	define JSILLog(...)		JSILLogA(__VA_ARGS__)
#else
#	define JSILLog(...)
#endif


#import <UIKit/UIKit.h>


@interface JSImageLoader : NSObject

// Singleton
+ (JSImageLoader *)sharedInstance;

@property (nonatomic, assign) NSUInteger cacheSize;

// Queue actions
- (void)suspendImageDownloads;
- (void)resumeImageDownloads;
- (void)cancelImageDownloads;

// Blocks
- (void)getImageAtURL:(NSURL *)url completionHandler:(void(^)(NSError *error, UIImage *image, NSURL *imageURL, BOOL cached))completionHandler;

@end
