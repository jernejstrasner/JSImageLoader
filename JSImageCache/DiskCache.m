//
//  DiskCache.m
//  happyhours
//
//  Created by Jernej Strasner on 5/23/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import "DiskCache.h"

#import "NSString-Crypto.h"

static DiskCache *sharedInstance_ = nil;

@interface DiskCache (Privates)

- (void)trimDiskCacheFilesToMaxSize:(NSUInteger)targetBytes;

@end


@implementation DiskCache

@synthesize sizeOfCache, cacheDir;

#pragma mark Initialization

- (id)init {
	self = [super init];
	if (self) {
		// Clean the cache
		[self trimDiskCacheFilesToMaxSize:kMaxDiskCacheSize];
	}
	return self;	
}

#pragma mark Singleton

+ (DiskCache *)sharedCache {
    @synchronized (self) {
        if (sharedInstance_ == nil) {
            sharedInstance_ = [[DiskCache alloc] init];
        }
    }
    return sharedInstance_;
}

#pragma mark Paths

- (NSString *)cacheDir {
	// Check if the cache dir is set
	if (_cacheDir == nil) {
		// Build the cache dir path
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
		_cacheDir = [[NSString alloc] initWithString:[[paths objectAtIndex:0] stringByAppendingPathComponent:@"URLCache"]];
	}
	
	// Check of the cache dir exists
	if (![[NSFileManager defaultManager] fileExistsAtPath:_cacheDir]) {
		// If it doesn't exist create it
		if (![[NSFileManager defaultManager] createDirectoryAtPath:_cacheDir withIntermediateDirectories:NO attributes:nil error:nil]) {
			NSLog(@"Error creating cache directory");
		}
	}
	
	// Finally return the path to it
	return _cacheDir;
}

- (NSString *)localPathForURL:(NSURL *)url {
	// Build the file name
	NSString *filename = [[url absoluteString] md5];

	// Return the full local path
	return [[self cacheDir] stringByAppendingPathComponent:filename];
}

#pragma mark Get the cached data

- (NSData *)imageDataInCacheForURLString:(NSString *)urlString {
	// Get the path for the local file equivalent
	NSString *localPath = [self localPathForURL:[NSURL URLWithString:urlString]];
	
	// Check of it exists
	if ([[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
		// "touch" the file so we know when it was last used
		[[NSFileManager defaultManager] setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSDate date], NSFileModificationDate, nil] 
										 ofItemAtPath:localPath 
												error:nil];
		// Return the file data
		return [[NSFileManager defaultManager] contentsAtPath:localPath];
	}
	
	// Else return nil
	return nil;
}

#pragma mark Cache data

- (void)cacheImageData:(NSData *)imageData request:(NSURLRequest *)request response:(NSURLResponse *)response {
	// Check of all the parameters are present and valid
	if (request != nil && response != nil && imageData != nil) {
		// Create a cached url response
		NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:imageData];
		// Store it in the url cache
		[[NSURLCache sharedURLCache] storeCachedResponse:cachedResponse forRequest:request];
		
		// Trim the ache if it exceeds the max size
		if ([self sizeOfCache] >= kMaxDiskCacheSize) {
			[self trimDiskCacheFilesToMaxSize:kMaxDiskCacheSize * 0.75];
		}
		
		// Get the local file path
		NSString *localPath = [self localPathForURL:[request URL]];
		
		// Check if the file exists at the path
		if (![[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
			// Try to create the file with the provided data
			if (![[NSFileManager defaultManager] createFileAtPath:localPath contents:imageData attributes:nil]) {
				NSLog(@"ERROR: Could not create file at path: %@", localPath);
			} else {
				// If the file was sucessfully created increase the total cache size by the size of the just cache data
				_cacheSize += [imageData length];
			}
		}
		
		// Clean up
        [cachedResponse release];
	}
}

#pragma mark Cache cleaning

- (void)clearCachedDataForRequest:(NSURLRequest *)request {
	// Remove the cache in the shared URL cache
	[[NSURLCache sharedURLCache] removeCachedResponseForRequest:request];
	// Get the data of the disk cache for the request
	NSData *data = [self imageDataInCacheForURLString:[[request URL] path]];
	// Decrease the total cache size by the data that will be removed
	_cacheSize -= [data length];
	// Remove the cache file from disk
	[[NSFileManager defaultManager] removeItemAtPath:[self localPathForURL:[request URL]] error:nil];
}

- (NSUInteger)sizeOfCache {
	// Get the path of the cache directory
	NSString *cacheDirectory = [self cacheDir];
	// Check if the cache size is not calculated yet and that the cache directory is valid
	if (_cacheSize <= 0 && cacheDirectory) {
		// Get the contents of the cache
		NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:cacheDirectory error:nil];
		// Variables for the loop
		NSDictionary *attrs;
		NSNumber *fileSize;
		NSString *pathExt;
		NSUInteger totalSize = 0;
		// Loop trough the cache contents
		for (NSString *file in dirContents) {
			// Get the file extension
			pathExt = [file pathExtension];
			// Check if the file is a jpg or png image
			if ([pathExt isEqualToString:@"jpg"] || [pathExt isEqualToString:@"png"]) {
				// Get the file attributes
				attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:[cacheDir stringByAppendingPathComponent:file] error:nil];
				// Get the file size from the attributes dictionary
				fileSize = [attrs objectForKey:NSFileSize];
				// Add to the total cache size
				totalSize += [fileSize integerValue];
			}
		}
		// Assign to the ivar
		_cacheSize = totalSize;
	}

	// Return the total cache size
	return _cacheSize;
}


NSInteger dateModifiedSort(id file1, id file2, void *reverse) {
	// This function sorts 2 files by their modification date
	// Get the attributes of both files
	NSDictionary *attrs1 = [[NSFileManager defaultManager] attributesOfItemAtPath:file1 error:nil];
	NSDictionary *attrs2 = [[NSFileManager defaultManager] attributesOfItemAtPath:file2 error:nil];
	
	// Check for the 3rd parameter that is a BOOL which defines if the sort is reverse
	if ((BOOL *)reverse == NO) {
		return [[attrs2 objectForKey:NSFileModificationDate] compare:[attrs1 objectForKey:NSFileModificationDate]];
	} else {
		return [[attrs1 objectForKey:NSFileModificationDate] compare:[attrs2 objectForKey:NSFileModificationDate]];
	}
}


- (void)trimDiskCacheFilesToMaxSize:(NSUInteger)targetBytes {
	// Determine the target size of the cache
	targetBytes = MIN(kMaxDiskCacheSize, MAX(0, targetBytes));
	// Check if the currnet cache size is bigger than the target
	if ([self sizeOfCache] > targetBytes) {
		// Get the cache contents
		NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self cacheDir] error:nil];
		
		NSMutableArray *filteredArray = [[NSMutableArray alloc] init];
		// Loop trough the cache contents and filter out images (jpg, png)
		for (NSString *file in dirContents) {
			NSString *pathExt = [file pathExtension];
			if ([pathExt isEqualToString:@"jpg"] || [pathExt isEqualToString:@"png"]) {
				[filteredArray addObject:[[self cacheDir] stringByAppendingPathComponent:file]];
			}
		}
		
		// Sort the images by modification date
		BOOL reverse = YES;
		NSMutableArray *sortedDirContents = [NSMutableArray arrayWithArray:[filteredArray sortedArrayUsingFunction:dateModifiedSort context:&reverse]];
		// While the cache size is bigger than the target size and the cache contents still exist
		while (_cacheSize > targetBytes && [sortedDirContents count] > 0) {
			// Decrease the total cache size b the size of the file to be removed
			_cacheSize -= [[[[NSFileManager defaultManager] attributesOfItemAtPath:[sortedDirContents lastObject] error:nil] objectForKey:NSFileSize] integerValue];
			// Remove the file
			[[NSFileManager defaultManager] removeItemAtPath:[sortedDirContents lastObject] error:nil];
			// Remove from the array
			[sortedDirContents removeLastObject];
		}
		// Clean up
        [filteredArray release];
	}
}

#pragma mark Memory management

- (void)dealloc {
	[_cacheDir release];
	
	[super dealloc];
}

@end
