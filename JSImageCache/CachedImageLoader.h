//
//  CachedImageLoader.h
//  happyhours
//
//  Created by Jernej Strasner on 5/23/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CachedImageClient.h"

#define MAX_NUMBER_OF_RETRIES 2

@protocol CachedImageConsumer;

@interface CachedImageLoader : NSObject {
@private
	NSOperationQueue *_imageDownloadQueue;
}

+ (CachedImageLoader *)sharedInstance;

- (void)addClientToDownloadQueue:(CachedImageClient *)client;
- (UIImage *)cachedImageForClient:(CachedImageClient *)client;

- (void)suspendImageDownloads;
- (void)resumeImageDownloads;
- (void)cancelImageDownloads;

@end

@protocol CachedImageConsumer <NSObject>

@required
- (void)renderImage:(UIImage *)image forClient:(CachedImageClient *)client;

@end