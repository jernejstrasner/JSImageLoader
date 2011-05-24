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

#import "CachedImageLoader.h"
#import "DiskCache.h"

#import <libkern/OSAtomic.h>

#define kNumberOfRetries 5

const NSInteger kMaxDownloadConnections	= 1;


@interface CachedImageLoader (Private)

- (void)loadImageForClient:(CachedImageClient *)client;
- (BOOL)loadImageRemotelyForClient:(CachedImageClient *)request;

@end


@implementation CachedImageLoader

#pragma mark Initialization

- (id)init {
	self = [super init];
	if (self) {
		// Initialize the queue
		_imageDownloadQueue = [[NSOperationQueue alloc] init];
		[_imageDownloadQueue setMaxConcurrentOperationCount:kMaxDownloadConnections];
	}
	return self;
}

#pragma mark Singleton

/*
 * Singleton pattern by Louis Gerbarg
 * http://stackoverflow.com/questions/145154/what-does-your-objective-c-singleton-look-like/2449664#2449664
 */

static void * volatile sharedInstance = nil;

+ (CachedImageLoader *)sharedInstance {
	while (!sharedInstance) {
		CachedImageLoader *temp = [[self alloc] init];
		if(!OSAtomicCompareAndSwapPtrBarrier(0x0, temp, &sharedInstance)) {
			[temp release];
		}
	}
	return sharedInstance;
}

#pragma mark Add the operations

- (void)addClientToDownloadQueue:(CachedImageClient *)client {
	[client retain];
	// Check if the image for this client is in the cache
    UIImage *cachedImage = [self cachedImageForClient:client];
    if (cachedImage) {
		// Render the image
		[client.client renderImage:cachedImage forClient:client];
    } else {
		// Create an operation and add to the queue
		[_imageDownloadQueue setSuspended:NO];
		NSInvocationOperation *imageDownloadOp = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(loadImageForClient:) object:client] autorelease];
		[_imageDownloadQueue addOperation:imageDownloadOp];
		client.fetchOperation = imageDownloadOp;
	}
	[client release];
}

- (void)loadImageForClient:(CachedImageClient *)client {
	[client retain];
	// Create an autorelease pool because we are on a background thread
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	// Load the image
	if (![self loadImageRemotelyForClient:client] && [client retries] < MAX_NUMBER_OF_RETRIES) {
		// If it fails retry
		NSLog(@"CachedImageLoader: image download failed, trying again...");
		client.retries = client.retries + 1;
		[self addClientToDownloadQueue:client];
	}
	// Empty the pool
	[pool drain];
	[client release];
}

#pragma mark Actions

- (void)suspendImageDownloads {
	[_imageDownloadQueue setSuspended:YES];
}

- (void)resumeImageDownloads {
	[_imageDownloadQueue setSuspended:NO];
}

- (void)cancelImageDownloads {
	[_imageDownloadQueue cancelAllOperations];
}

#pragma mark Caching methods

- (UIImage *)cachedImageForClient:(CachedImageClient *)client {
	// Variables
	NSData *imageData = nil;
	UIImage *image = nil;
	// Get the request from the client
	NSURLRequest *request = [client request];
	// Try the in-memory cache
	NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
	if (cachedResponse) {
		imageData = [cachedResponse data];
		image = [UIImage imageWithData:imageData];
		
		return image;
	}
	
	// Try the on-disk cache
	imageData = [[DiskCache sharedCache] imageDataInCacheForURLString:[[request URL] absoluteString]];
	if (imageData) {
		// Determine the MIME type
		NSString *mimeType = [[[request URL] path] pathExtension];
		if ([mimeType isEqualToString:@"jpg"]) {
			mimeType = @"jpeg";
		}
		// Build a URL response
		NSURLResponse *response = [[[NSURLResponse alloc] initWithURL:[request URL]
															 MIMEType:[NSString stringWithFormat:@"image/%@", mimeType]
												expectedContentLength:[imageData length]
													 textEncodingName:nil]
								   autorelease];
		// Re-cache the data (actually only modifies the modification date on the file)
		[[DiskCache sharedCache] cacheImageData:imageData 
										 request:request 
										response:response];
		
		// Return the image
		image = [UIImage imageWithData:imageData];
		return image;
	}
	
	return image;
}

- (void)renderImageOnMainThread:(NSDictionary *)userInfo {
	// Go to the main thread if needed
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:@selector(renderImageOnMainThread:) withObject:userInfo waitUntilDone:NO];
		return;
	}
	CachedImageClient *client = [userInfo valueForKey:@"client"];
	UIImage *image = [userInfo valueForKey:@"image"];
	
	// Render the image
	[client.client renderImage:image forClient:client];
}

- (BOOL)loadImageRemotelyForClient:(CachedImageClient *)client {
	// Load the image remotely
	// Get the request
	NSURLRequest *request = [client request];
	if (!request || ![request URL]) {
		return NO;
	}
	// Syncrounously get the data
	NSURLResponse *response = nil;
	NSError *error = nil;
	NSData *imageData = [NSURLConnection sendSynchronousRequest:request
											  returningResponse:&response
														  error:&error];
	
	// Check for errors
	if (error) {
		NSLog(@"ERROR RETRIEVING IMAGE at %@: %@", [request URL], [error localizedDescription]);

        NSInteger code = [error code];
        if (code == NSURLErrorUnsupportedURL ||
            code == NSURLErrorBadURL ||
            code == NSURLErrorBadServerResponse ||
            code == NSURLErrorRedirectToNonExistentLocation ||
            code == NSURLErrorFileDoesNotExist ||
            code == NSURLErrorFileIsDirectory ||
            code == NSURLErrorRedirectToNonExistentLocation) {
            // the above status codes are permanent fatal errors; don't retry
            return YES;
        }
	} else if (imageData != nil && response != nil) {
		// Cache the data
		[[DiskCache sharedCache] cacheImageData:imageData 
										 request:request
										response:response];
		// Build an image from the data
		UIImage *image = [UIImage imageWithData:imageData];
		// Check if it is a valid image
		if (!image) {
			// Clear the cache
			[[DiskCache sharedCache] clearCachedDataForRequest:request];
			// Still call the delegate but with nil (so the delegate can stop loading indicators, etc. and show an error perhaps)
			[self renderImageOnMainThread:[NSDictionary dictionaryWithObjectsAndKeys:client, @"client", nil]];
			// Return yes because we don't want to keep retrying the download of a corrupted image
			return YES;
		} else {
			// Send the image to the client
			[self renderImageOnMainThread:[NSDictionary dictionaryWithObjectsAndKeys:image, @"image", client, @"client", nil]];
			// Return
			return YES;
		}
	} else {
		NSLog(@"Unknown error retrieving image at: %@ (response is null)", [request URL]);
	}
	
	// If everything fails return NO
	return NO;
}

#pragma mark Memory management

- (void)dealloc {
	// Clean up the queue
	[_imageDownloadQueue cancelAllOperations];
	[_imageDownloadQueue release];
	// Super
	[super dealloc];
}

@end
