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

@interface JSImageLoader()
@property (nonatomic, strong) NSOperationQueue *downloadQueue;
@end

@implementation JSImageLoader

#pragma mark - Lifecycle

+ (JSImageLoader *)sharedInstance
{
	static JSImageLoader *sharedInstance = nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		sharedInstance = [[JSImageLoader alloc] init];
	});
	
	return sharedInstance;
}

- (id)init
{
	self = [super init];
	if (self) {
		// Initialize the queue
		_downloadQueue = [[NSOperationQueue alloc] init];
		[_downloadQueue setMaxConcurrentOperationCount:JSImageLoaderMaxDownloadConnections];
	}
	return self;
}

- (void)dealloc
{
	// Clean up the queue
	[_downloadQueue cancelAllOperations];
}

#pragma mark - Actions

- (void)suspendImageDownloads
{
	[self.downloadQueue setSuspended:YES];
}

- (void)resumeImageDownloads
{
	[self.downloadQueue setSuspended:NO];
}

- (void)cancelImageDownloads
{
	[self.downloadQueue cancelAllOperations];
}

#pragma mark - Block methods

typedef void (^js_completion_handler_t)(NSError *error, UIImage *image, NSURL *imageURL, BOOL cached);

- (void)getImageAtURL:(NSURL *)url completionHandler:(js_completion_handler_t)completionHandler
{
	js_completion_handler_t executeCompletionHandlerOnMainQueue = ^(NSError *error, UIImage *image, NSURL *imageURL, BOOL cached) {
		if (completionHandler) {
			dispatch_async(dispatch_get_main_queue(), ^(void) {
				completionHandler(error, image, imageURL, cached);
			});
		}
	};

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
		// Create a request
		NSURLRequest *request = [NSURLRequest requestWithURL:url];
		
#warning TODO: Check the cache for the image
		
		// Load the image remotely
		[self.downloadQueue addOperationWithBlock:^{
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
							executeCompletionHandlerOnMainQueue(error, nil, url, NO);
							return;
						}
						default:
						{
							// retry
							if (retries_counter < 1) {
								executeCompletionHandlerOnMainQueue(error, nil, url, NO);
								return;
							}
							continue;
						}
					}
				}
				else if (imageData != nil && response != nil) {
					// Build an image from the data
					UIImage *image = [UIImage imageWithData:imageData];
					if (!image) {
						executeCompletionHandlerOnMainQueue([NSError errorWithDomain:JSImageLoaderErrorDomain code:2 userInfo:@{NSLocalizedDescriptionKey: @"Invalid image data"}], nil, url, NO);
						return;
					}
					else {
#warning TODO: Cache the data
						executeCompletionHandlerOnMainQueue(nil, image, url, NO);
						return;
					}
				}
				else {
					executeCompletionHandlerOnMainQueue([NSError errorWithDomain:JSImageLoaderErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"The image failed to download."}], nil, url, NO);
					return;
				}
				
			}
			
		}];
	});
}

@end