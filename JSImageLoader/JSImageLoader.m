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

#define kNumberOfRetries 2
#define kMaxDownloadConnections	1


@interface JSImageLoader () {
@private
	NSOperationQueue *_imageDownloadQueue;
}

@end

@implementation JSImageLoader

#pragma mark - Object lifecycle

- (id)init
{
	self = [super init];
	if (self) {
		// Initialize the queue
		_imageDownloadQueue = [[NSOperationQueue alloc] init];
		[_imageDownloadQueue setMaxConcurrentOperationCount:kMaxDownloadConnections];
	}
	return self;
}

- (void)dealloc
{
	// Clean up the queue
	[_imageDownloadQueue cancelAllOperations];
	[_imageDownloadQueue release];
	// Super
	[super dealloc];
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

- (void)getImageAtURL:(NSURL *)url completionHandler:(void(^)(NSError *error, UIImage *image, NSURL *imageURL))completionHandler
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
		// Create a request
		NSURLRequest *request = [NSURLRequest requestWithURL:url];
		
		// Check the cache
		NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
		if (cachedResponse) {
			dispatch_async(dispatch_get_main_queue(), ^(void) {
				completionHandler(nil, [UIImage imageWithData:[cachedResponse data]], url);
			});
			return;
		}
		
		// Load the image remotely
		[_imageDownloadQueue addOperationWithBlock:^{
			NSURLResponse *response = nil;
			NSError *error = nil;
			
			// Retries
			int retries_counter = kNumberOfRetries;
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
							dispatch_async(dispatch_get_main_queue(), ^(void) {
								completionHandler(error, nil, url);
							});
							return;
						default:
							// retry
							if (retries_counter < 1) return;
							continue;
					}
				}
				else if (imageData != nil && response != nil) {
					// Build an image from the data
					UIImage *image = [UIImage imageWithData:imageData];
					if (!image) {
						dispatch_async(dispatch_get_main_queue(), ^(void) {
							completionHandler([NSError errorWithDomain:@"com.jernejstrasner.imageloader" code:2 userInfo:[NSDictionary dictionaryWithObject:@"Invalid image data" forKey:NSLocalizedDescriptionKey]], nil, url);
						});
						return;
					} else {
						// Image is valid, cache the data
						[[NSURLCache sharedURLCache] storeCachedResponse:[[[NSCachedURLResponse alloc] initWithResponse:response data:imageData] autorelease] forRequest:request];
						
						dispatch_async(dispatch_get_main_queue(), ^(void) {
							completionHandler(nil, image, url);
						});
						return;
					}
				} else {
					dispatch_async(dispatch_get_main_queue(), ^(void) {
						completionHandler([NSError errorWithDomain:@"com.jernejstrasner.imageloader" code:1 userInfo:[NSDictionary dictionaryWithObject:@"The image failed to download." forKey:NSLocalizedDescriptionKey]], nil, url);
					});
					return;
				}
				
			}
			
		}];
	});
}

@end