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
//  DiskCache.h
//  JSImageCache
//
//  Created by Jernej Strasner on 5/23/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

// Some though should be applied here.  For instance the current trimming algorithm removes cached image
// files until the disc cache returns to approximatyely 75% of capacity. So you wouldn't want image sizes
// bigger than 1/4 of the cache size or trims would happen for each image request.
#define kMaxDiskCacheSize 10e6

// Uncomment to enable debugging NSLog statements
//#define DiskCacheDebug


@interface JSImageLoaderCache : NSObject

@property (nonatomic, readonly) NSUInteger sizeOfCache;
@property (nonatomic, readonly) NSString *cacheDir;

+ (JSImageLoaderCache *)sharedCache;

- (NSData *)imageDataInCacheForURLString:(NSString *)urlString;
- (void)cacheImageData:(NSData *)imageData
			   request:(NSURLRequest *)request
			  response:(NSURLResponse *)response;
- (void)clearCachedDataForRequest:(NSURLRequest *)request;


@end
