//
//  JSILCache.h
//  JSImageLoader
//
//  Created by Jernej Strasner on 1/28/14.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface JSILCache : NSObject

+ (JSILCache *)sharedCache;

@property (nonatomic, assign) NSUInteger cacheSize;

- (void)cacheImage:(UIImage *)image forURL:(NSURL *)url;
- (void)imageForURL:(NSURL *)url completion:(void(^)(UIImage *image))completion;

@end
