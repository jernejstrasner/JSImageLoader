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
//  CachedImageLoader.m
//  JSImageCache
//
//  Created by Jernej Strasner on 5/23/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import "JSImageLoader.h"

static NSString * const JSImageLoaderErrorDomain						= @"com.jernejstrasner.imageloader";
static NSUInteger const JSImageLoaderNumberOfRetries					= 2;
static NSUInteger const JSImageLoaderMaxDownloadConnections				= 1;
static NSUInteger const JSImageLoaderCacheMemoryCapacity				= 10;
static NSUInteger const JSImageLoaderCacheDiskCapacity					= 10;

@interface JSImageLoader()

@property (nonatomic, strong) NSURLCache *urlCache;

@end

@implementation JSImageLoader {
	NSOperationQueue *_imageDownloadQueue;
}

#pragma mark - Object lifecycle

- (id)init
{
	self = [super init];
	if (self) {
		// Initialize the queue
		_imageDownloadQueue = [[NSOperationQueue alloc] init];
		[_imageDownloadQueue setMaxConcurrentOperationCount:JSImageLoaderMaxDownloadConnections];

		// Set the fallback values for the cache capacity
		_memoryCapacity = JSImageLoaderCacheMemoryCapacity * 1024 * 1024;
		_diskCapacity = JSImageLoaderCacheDiskCapacity * 1024 * 1024;
	}
	return self;
}

- (void)dealloc
{
	// Clean up the queue
	[_imageDownloadQueue cancelAllOperations];
}

#pragma mark - Custom caching

- (void)initializeCache:(BOOL)useOwnCache
{
	// Initialize the URL cache
	// If we use custom caching, set up the path suffix and the capacities
	if (useOwnCache) {
		_urlCache = [[NSURLCache alloc] initWithMemoryCapacity:self.memoryCapacity
												  diskCapacity:self.diskCapacity
													  diskPath:JSImageLoaderErrorDomain];
	}
	// Otherwise use the shared URL cache, possibly controlled by the container app
	else {
		_urlCache = [NSURLCache sharedURLCache];
	}
}

- (NSURLCache *)urlCache
{
	// Make sure that the cache is properly initialized taking into account the custom caching flag
	if (!_urlCache) {
		[self initializeCache:self.useOwnCache];
	}

	return _urlCache;
}

- (void)setUseOwnCache:(BOOL)useOwnCache
{
	// When the custom caching flag changes we have to make sure that it initializes/sets the right URL cache
	if (_useOwnCache == useOwnCache) return;

	[self initializeCache:useOwnCache];
	_useOwnCache = useOwnCache;
}

- (void)setMemoryCapacity:(NSUInteger)memoryCapacity
{
	if (_memoryCapacity == memoryCapacity) return;

	[self.urlCache setMemoryCapacity:memoryCapacity];
	_memoryCapacity = memoryCapacity;
}

- (void)setDiskCapacity:(NSUInteger)diskCapacity
{
	if (_diskCapacity == diskCapacity) return;

	[self.urlCache setDiskCapacity:diskCapacity];
	_diskCapacity = diskCapacity;
}

#pragma mark - Singleton

+ (JSImageLoader *)sharedInstance
{
	static JSImageLoader *sharedInstance = nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		sharedInstance = [[JSImageLoader alloc] init];
	});

	return sharedInstance;
}

#pragma mark - Actions

- (void)suspendImageDownloads
{
	[_imageDownloadQueue setSuspended:YES];
}

- (void)resumeImageDownloads
{
	[_imageDownloadQueue setSuspended:NO];
}

- (void)cancelImageDownloads
{
	[_imageDownloadQueue cancelAllOperations];
}

#pragma mark - Block methods

- (void)getImageAtURL:(NSURL *)url completionHandler:(void(^)(NSError *error, UIImage *image, NSURL *imageURL, BOOL cached))completionHandler
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
		// Create a request
		NSURLRequest *request = [NSURLRequest requestWithURL:url];
		// Check the cache
		NSCachedURLResponse *cachedResponse = [self.urlCache cachedResponseForRequest:request];
		if (cachedResponse) {
			dispatch_async(dispatch_get_main_queue(), ^(void) {
				completionHandler(nil, [UIImage imageWithData:[cachedResponse data]], url, YES);
			});
			return;
		}

		// Load the image remotely
		[_imageDownloadQueue addOperationWithBlock:^{
			NSURLResponse *response = nil;
			NSError *error = nil;
			
			// Retries
			int retries_counter = JSImageLoaderNumberOfRetries;
			NSData *imageData;
			while(1) {
				retries_counter--;

				imageData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
				if (error) {
					switch ([error code]) {
						case NSURLErrorUnsupportedURL:
						case NSURLErrorBadURL:
						case NSURLErrorBadServerResponse:
						case NSURLErrorRedirectToNonExistentLocation:
						case NSURLErrorFileDoesNotExist:
						case NSURLErrorFileIsDirectory:
						{
							dispatch_async(dispatch_get_main_queue(), ^(void) {
								completionHandler(error, nil, url, NO);
							});
							return;
						}
						default:
						{
							// retry
							if (retries_counter < 1) return;
							continue;
						}
					}
				}
				else if (imageData != nil && response != nil) {
					// Build an image from the data
					UIImage *image = [UIImage imageWithData:imageData];
					if (!image) {
						dispatch_async(dispatch_get_main_queue(), ^(void) {
							completionHandler([NSError errorWithDomain:JSImageLoaderErrorDomain code:2 userInfo:@{NSLocalizedDescriptionKey: @"Invalid image data"}], nil, url, NO);
						});
						return;
					} else {
						// Image is valid, cache the data
						[self.urlCache storeCachedResponse:[[NSCachedURLResponse alloc] initWithResponse:response data:imageData] forRequest:request];

						dispatch_async(dispatch_get_main_queue(), ^(void) {
							completionHandler(nil, image, url, NO);
						});
						return;
					}
				} else {
					dispatch_async(dispatch_get_main_queue(), ^(void) {
						completionHandler([NSError errorWithDomain:JSImageLoaderErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"The image failed to download."}], nil, url, NO);
					});
					return;
				}
				
			}
			
		}];
	});
}

@end