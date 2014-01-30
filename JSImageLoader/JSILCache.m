//
//  JSILCache.m
//  JSImageLoader
//
//  Created by Jernej Strasner on 1/28/14.
//
//

#import "JSILCache.h"

@interface JSILCache () {
	dispatch_queue_t databaseQueue;
}
@property (nonatomic, strong) FMDatabase *database;
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
	// Create the database queue
	databaseQueue = dispatch_queue_create("com.jernejstrasner.imageloader.database", 0);
	
	// Keep an open connection for fast access
	[self openDatabase];
	
	// Create database structure if not present
	dispatch_async(databaseQueue, ^{
		[self.database executeUpdate:@"CREATE TABLE IF NOT EXISTS images ( data BLOB, url TEXT PRIMARY KEY )"];
	});
	
	// Start listening for notifications so we can close the database properly
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeDatabase) name:UIApplicationWillTerminateNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeDatabase) name:UIApplicationDidEnterBackgroundNotification object:nil];
	
	// Open connection again if app enters foreground
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openDatabase) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (FMDatabase *)database
{
	if (!_database) {
		_database = [[FMDatabase alloc] initWithPath:[self databasePath]];
	}
	return _database;
}

- (void)openDatabase
{
	if (![self.database open]) {
		NSLog(@"[ERROR] %@", self.database.lastErrorMessage);
	}
}

- (void)closeDatabase
{
	dispatch_async(databaseQueue, ^{
		[self.database close];
	});
}

- (void)cacheImage:(UIImage *)image forURL:(NSURL *)url
{
	dispatch_async(databaseQueue, ^{
		NSData *imageData = [self dataFromImage:image];
		NSString *urlString = [url absoluteString];
		
		[self.database executeUpdate:@"INSERT OR REPLACE INTO images (data, url) VALUES (?, ?)", imageData, urlString];
	});
}

- (void)imageForURL:(NSURL *)url completion:(void(^)(UIImage *image))completion
{
	dispatch_async(databaseQueue, ^{
		NSString *urlString = [url absoluteString];
		
		FMResultSet *results = [self.database executeQuery:@"SELECT data FROM images WHERE url IS ? LIMIT 1", urlString];
		NSData *imageData;
		if ([results next]) {
			imageData = [results dataForColumn:@"data"];
		}
		
		UIImage *image;
		if (imageData.length) {
			image = [self imageFromData:imageData];
		}
		
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
	#warning TODO: Check if CGBitmapContext would be faster here
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

- (NSString *)databasePath
{
	return [[self cachePath] stringByAppendingPathComponent:@"ImageCache.db"];
}

@end
