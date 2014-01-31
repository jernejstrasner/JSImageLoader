//
//  JSILCache.m
//  JSImageLoader
//
//  Created by Jernej Strasner on 1/28/14.
//
//

#import "JSILCache.h"

#import "JSProfilingTimer.h"

#import <CommonCrypto/CommonCrypto.h>

@interface JSILCache () {
	dispatch_queue_t cacheQueue;
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
}

- (void)cacheImage:(UIImage *)image forURL:(NSURL *)url
{
	dispatch_async(cacheQueue, ^{
		js_timer_t img_t = JSProfilingTimerStart();
		NSData *imageData = [self dataFromImage:image];
		float img_time = JSProfilingTimerEnd(img_t);
		
		NSString *urlString = [url absoluteString];
		
		NSString *hash = [self md5HashFromString:urlString];
		NSString *path = [[self cachePath] stringByAppendingPathComponent:hash];
		
		js_timer_t write_t = JSProfilingTimerStart();
		[imageData writeToFile:path atomically:YES];
		float write_time = JSProfilingTimerEnd(write_t);
		
		NSLog(@"[WRITE] %0.2fs | Image conversion: %0.2fs | Data size: %0.2fkB", write_time, img_time, imageData.length/1024.0);
	});
}

- (void)imageForURL:(NSURL *)url completion:(void(^)(UIImage *image))completion
{
	dispatch_async(cacheQueue, ^{
		NSString *urlString = [url absoluteString];
		
		js_timer_t timer = JSProfilingTimerStart();
		NSData *imageData;
		NSString *hash = [self md5HashFromString:urlString];
		NSString *path = [[self cachePath] stringByAppendingPathComponent:hash];
		imageData = [[NSData alloc] initWithContentsOfFile:path];
		float fetch_t = JSProfilingTimerEnd(timer);
		
		UIImage *image;
		float img_t;
		if (imageData.length) {
			js_timer_t img_timer = JSProfilingTimerStart();
			image = [self imageFromData:imageData];
			img_t = JSProfilingTimerEnd(img_timer);
		}
		
		NSLog(@"[READ] %0.2fs | Image conversion: %0.2fs | Data size: %0.2fkB", fetch_t, img_t, imageData.length/1024.0);
		
		if (completion) {
			dispatch_async(dispatch_get_main_queue(), ^{
				completion(image);
			});
		}
	});
}

- (NSData *)dataFromImage:(UIImage *)image
{
	// We want to get uncompressed data here which is why we're not using UIImage(PNG|JPEG)Representation
	CGImageRef img = image.CGImage;
	size_t width = CGImageGetWidth(img);
	size_t height = CGImageGetHeight(img);
	size_t bpc = CGImageGetBitsPerComponent(img);
	size_t bpr = CGImageGetBytesPerRow(img);
	CGColorSpaceRef colorSpace = CGImageGetColorSpace(img);
	CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(img);
	
	void *imgData = malloc(bpr * height);
	
	CGContextRef context = CGBitmapContextCreate(imgData, width, height, bpc, bpr, colorSpace, bitmapInfo);
	CGContextDrawImage(context, CGContextGetClipBoundingBox(context), img);
	
	NSData *data = [[NSData alloc] initWithBytesNoCopy:imgData length:bpr * height freeWhenDone:YES];
	
	CGContextRelease(context);
	
	return data;
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
	
	NSString *cachePath = [searchPaths[0] stringByAppendingPathComponent:@"com.jernejstrasner.jsimageloader"];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir = NO;
	BOOL fileExists = [fm fileExistsAtPath:cachePath isDirectory:&isDir];
	
	if (fileExists && !isDir) {
		NSError *deletionError;
		[fm removeItemAtPath:cachePath error:&deletionError];
		if (deletionError) {
			NSLog(@"[ERROR] A file already exists and could not be deleted: %@", cachePath);
			return nil;
		}
	}
	else if (!fileExists) {
		NSError *error;
		[fm createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:&error];
		if (error) {
			NSLog(@"[ERROR] Cache directory could not be created at: %@", cachePath);
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
