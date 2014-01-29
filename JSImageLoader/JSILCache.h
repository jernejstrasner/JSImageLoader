//
//  JSILCache.h
//  JSImageLoader
//
//  Created by Jernej Strasner on 1/28/14.
//
//

#import <Foundation/Foundation.h>
#import <FMDB/FMDatabase.h>

@interface JSILCache : NSObject

- (void)cacheImage:(UIImage *)image forURL:(NSURL *)url;
- (void)imageForURL:(NSURL *)url completion:(void(^)(UIImage *image))completion;

@end
