//
//  JSILCache.m
//  JSImageLoader
//
//  Created by Jernej Strasner on 1/28/14.
//
//

#import "JSILCache.h"

#import "JSImageLoader.h"
#import "JSProfilingTimer.h"

#import <CommonCrypto/CommonCrypto.h>

@interface JSILCache () {
	dispatch_queue_t cacheQueue;
	dispatch_queue_t cleaningQueue;
}
@end

@implementation JSILCache

+ (JSILCache *)sharedCache
{
	static JSILCache *sharedCache = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedCache = [[JSILCache alloc] init];
	});
	return sharedCache;
}

- (id)init
{
	self = [super init];
	if (self) {
		[self setupCache];
	}
	return self;
}

- (void)setupCache
{
	cacheQueue = dispatch_queue_create("com.jernejstrasner.imageloader.cache", DISPATCH_QUEUE_CONCURRENT);
	cleaningQueue = dispatch_queue_create("com.jernejstrasner.imageloader.cleaning", DISPATCH_QUEUE_SERIAL);
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(cleanupCache)
												 name:UIApplicationDidEnterBackgroundNotification
											   object:nil];
}

- (void)cacheImage:(UIImage *)image forURL:(NSURL *)url
{
	dispatch_async(cacheQueue, ^{
#if LOGGING
		js_timer_t img_t = JSProfilingTimerStart();
#endif
		NSData *imageData = [self dataFromImage:image];
#if LOGGING
		float img_time = JSProfilingTimerEnd(img_t);
#endif
		
		NSString *urlString = [url absoluteString];
		
		NSString *hash = [self md5HashFromString:urlString];
		NSString *path = [[self cachePath] stringByAppendingPathComponent:hash];
		
#if LOGGING
		js_timer_t write_t = JSProfilingTimerStart();
#endif
		[imageData writeToFile:path atomically:YES];
#if LOGGING
		float write_time = JSProfilingTimerEnd(write_t);
#endif
		
		JSILLog(@"[WRITE] %0.2fs | NSData: %0.2fs | Data size: %0.2fkB", write_time, img_time, imageData.length/1024.0);
	});
}

- (void)cleanupCache
{
	__block UIBackgroundTaskIdentifier backgroundTaskID;
	backgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
		[[UIApplication sharedApplication] endBackgroundTask:backgroundTaskID];
		backgroundTaskID = UIBackgroundTaskInvalid;
	}];

	dispatch_async(cleaningQueue, ^{
		
		NSFileManager *fm = [NSFileManager defaultManager];
		
		NSUInteger cacheSize = 0;
		
		NSMutableArray *files = [[NSMutableArray alloc] init];

		NSArray *fileKeys = @[NSURLContentModificationDateKey, NSURLTotalFileAllocatedSizeKey];
		NSDirectoryEnumerator *dirEnum = [fm enumeratorAtURL:[NSURL fileURLWithPath:[self cachePath]]
								  includingPropertiesForKeys:fileKeys
													 options:0
												errorHandler:nil];
		for (NSURL *fileURL in dirEnum) {
			NSDictionary *metadata = [fileURL resourceValuesForKeys:fileKeys error:nil];
			if (metadata) {
				NSUInteger fileSize = [metadata[NSURLTotalFileAllocatedSizeKey] unsignedIntegerValue];
				cacheSize += fileSize;
				[files addObject:@{@"url": fileURL, @"size": @(fileSize), @"date": metadata[NSURLContentModificationDateKey]}];
			}
		}
		
		if (cacheSize > self.cacheSize) {
			NSUInteger targetSize = self.cacheSize*2/3;
			
			[files sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]]];
			
			for (NSDictionary *fd in files) {
				if ([fm removeItemAtURL:fd[@"url"] error:nil]) {
					cacheSize -= [fd[@"size"] unsignedIntegerValue];
					JSILLog(@"[CACHE] [%0.2fkB] Removed %@", (cacheSize/1024.0f), fd[@"url"]);
					if (cacheSize <= targetSize) break;
				}
			}
		}
		
		[[UIApplication sharedApplication] endBackgroundTask:backgroundTaskID];
		backgroundTaskID = UIBackgroundTaskInvalid;
	});
}

- (void)imageForURL:(NSURL *)url completion:(void(^)(UIImage *image))completion
{
	dispatch_async(cacheQueue, ^{
		NSString *urlString = [url absoluteString];
#if LOGGING
		js_timer_t timer = JSProfilingTimerStart();
#endif
		NSData *imageData;
		NSString *hash = [self md5HashFromString:urlString];
		NSString *path = [[self cachePath] stringByAppendingPathComponent:hash];
		imageData = [[NSData alloc] initWithContentsOfFile:path];
#if LOGGING
		float fetch_t = JSProfilingTimerEnd(timer);
#endif
		
		UIImage *image;
#if LOGGING
		float img_t = 0.0f;
#endif
		if (imageData.length) {
#if LOGGING
			js_timer_t img_timer = JSProfilingTimerStart();
#endif
			image = [self imageFromData:imageData];
#if LOGGING
			img_t = JSProfilingTimerEnd(img_timer);
#endif
		}
		
		// Update modified date, to keep the cache from deleting it too early
		if (image) {
			NSURL *imageFileURL = [NSURL fileURLWithPath:path];
			NSError *error;
			if (![imageFileURL setResourceValue:[NSDate date] forKey:NSURLContentModificationDateKey error:&error]) {
				JSILLog(@"[WARNING] The last modified date could not be updated for image %@. Error: %@", hash, error.localizedDescription);
			}
		}
		
		JSILLog(@"[READ] %0.2fs | UIImage: %0.2fs | Size: %0.2fkB", fetch_t, img_t, imageData.length/1024.0);
		
		if (completion) {
			dispatch_async(dispatch_get_main_queue(), ^{
				completion(image);
			});
		}
	});
}

// TODO: Could probably be optimized by writing bitmap data to disk and then mapping into memory using mmap

- (NSData *)dataFromImage:(UIImage *)image
{
	return UIImagePNGRepresentation(image);
}

- (UIImage *)imageFromData:(NSData *)data
{
	return [[UIImage alloc] initWithData:data];
}

#pragma mark - Paths

- (NSString *)cachePath
{
	NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	
	if (!searchPaths.count) return nil;
	
	NSString *cachePath = [searchPaths[0] stringByAppendingPathComponent:@"com.jernejstrasner.jsimageloader.images"];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir = NO;
	BOOL fileExists = [fm fileExistsAtPath:cachePath isDirectory:&isDir];
	
	if (fileExists && !isDir) {
		NSError *deletionError;
		[fm removeItemAtPath:cachePath error:&deletionError];
		if (deletionError) {
			JSILLogA(@"[ERROR] A file already exists and could not be deleted: %@", cachePath);
			return nil;
		}
	}
	else if (!fileExists) {
		NSError *error;
		[fm createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:&error];
		if (error) {
			JSILLogA(@"[ERROR] Cache directory could not be created at: %@", cachePath);
			return nil;
		}
	}
	
	return cachePath;
}

#pragma mark - Utility

- (NSString *)md5HashFromString:(NSString *)string
{
	const char *cStr = [string UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), result ); // This is the md5 call

	NSMutableString *hash = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
	for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
		[hash appendFormat:@"%02x", result[i]];
	}
	
	return [NSString stringWithString:hash];
}

@end
