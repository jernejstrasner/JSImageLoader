//
//  JSILCache.h
//  JSImageLoader
//
//  Created by Jernej Strasner on 1/28/14.
//
//

#import <Foundation/Foundation.h>

@interface JSILCache : NSObject

+ (JSILCache *)sharedCache;

- (void)cacheImage:(UIImage *)image forURL:(NSURL *)url;
- (void)imageForURL:(NSURL *)url completion:(void(^)(UIImage *image))completion;

@end
