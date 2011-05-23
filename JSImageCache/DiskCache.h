//
//  DiskCache.h
//  happyhours
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


@interface DiskCache : NSObject {
@private
	NSString *_cacheDir;
	NSUInteger _cacheSize;
}

@property (nonatomic, readonly) NSUInteger sizeOfCache;
@property (nonatomic, readonly) NSString *cacheDir;

+ (DiskCache *)sharedCache;

- (NSData *)imageDataInCacheForURLString:(NSString *)urlString;
- (void)cacheImageData:(NSData *)imageData
			   request:(NSURLRequest *)request
			  response:(NSURLResponse *)response;
- (void)clearCachedDataForRequest:(NSURLRequest *)request;


@end
