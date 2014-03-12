//
//  CachedImageLoader.m
//  JSImageCache
//
//  Created by Jernej Strasner on 5/23/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import "JSImageLoader.h"

#import "JSILCache.h"

#define JSILExecuteBlockOnMainThread(block, ...) if (block) { dispatch_async(dispatch_get_main_queue(), ^{ block(__VA_ARGS__); }); }

static NSString * const JSImageLoaderErrorDomain						= @"com.jernejstrasner.imageloader";
static NSUInteger const JSImageLoaderNumberOfRetries					= 2;
static NSUInteger const JSImageLoaderMaxDownloadConnections				= 3;

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

#pragma mark - Properties

- (void)setCacheSize:(NSUInteger)cacheSize
{
	[[JSILCache sharedCache] setCacheSize:cacheSize];
}

- (NSUInteger)cacheSize
{
	return [[JSILCache sharedCache] cacheSize];
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
	if (!url) {
		JSILLogA(@"URL cannot be nil!");
		return;
	}
	
	[[JSILCache sharedCache] imageForURL:url completion:^(UIImage *image) {
		// If we have the image call the completion block and return
		if (image) {
			JSILExecuteBlockOnMainThread(completionHandler, nil, image, url, YES);
			return;
		}
		
		// Looks like we didn't find the image. Download it.
		[self.downloadQueue addOperationWithBlock:^{
			NSURLRequest *request = [NSURLRequest requestWithURL:url];
			NSURLResponse *response;
			NSError *error;
			
			// Retries
			int retries_counter = JSImageLoaderNumberOfRetries;
			NSData *imageData;
			while(retries_counter--) {
				imageData = [NSURLConnection sendSynchronousRequest:request
												  returningResponse:&response
															  error:&error];
				if (error) {
					switch ([error code]) {
						case NSURLErrorUnsupportedURL:
						case NSURLErrorBadURL:
						case NSURLErrorBadServerResponse:
						case NSURLErrorRedirectToNonExistentLocation:
						case NSURLErrorFileDoesNotExist:
						case NSURLErrorFileIsDirectory:
						{
							JSILExecuteBlockOnMainThread(completionHandler, error, nil, url, NO);
							return;
						}
						default:
						{
							// retry
							if (retries_counter < 1) {
								JSILExecuteBlockOnMainThread(completionHandler, error, nil, url, NO);
								return;
							}
							continue;
						}
					}
				}
				else if (imageData.length && response) {
					// Build an image from the data
					UIImage *loadedImage = [UIImage imageWithData:imageData];
					if (!loadedImage) {
						NSError *imageError = [NSError errorWithDomain:JSImageLoaderErrorDomain code:2 userInfo:@{NSLocalizedDescriptionKey: @"Invalid image data"}];
						JSILExecuteBlockOnMainThread(completionHandler, imageError, nil, url, NO);
						return;
					}
					else {
						// Cache the image
						[[JSILCache sharedCache] cacheImage:loadedImage forURL:url];
						// Callback
						JSILExecuteBlockOnMainThread(completionHandler, nil, loadedImage, url, NO);
						return;
					}
				}
				else {
					NSError *loadingError = [NSError errorWithDomain:JSImageLoaderErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"The image failed to download."}];
					JSILExecuteBlockOnMainThread(completionHandler, loadingError, nil, url, NO);
					return;
				}
			}
		}];
	}];
}

@end