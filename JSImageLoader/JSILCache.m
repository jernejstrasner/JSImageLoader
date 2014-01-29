//
//  JSILCache.m
//  JSImageLoader
//
//  Created by Jernej Strasner on 1/28/14.
//
//

#import "JSILCache.h"

@implementation JSILCache

#pragma mark - Paths

+ (NSString *)cachePath
{
	NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	
	if (!searchPaths.count) return nil;
	
	NSString *cachePath = [searchPaths[0] stringByAppendingPathComponent:@"com.jernejstrasner.jsimageloader"];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir = NO;
	BOOL fileExists = [fm fileExistsAtPath:cachePath isDirectory:&isDir];
	
	if (fileExists && isDir) {
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

+ (NSString *)cacheDatabasePath
{
	return [[self cachePath] stringByAppendingPathComponent:@"cache.db"];
}

@end
