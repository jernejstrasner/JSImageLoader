//
//  NSObject+Threading.m
//  FollowTheFace
//
//  Created by Jernej Strasner on 4/30/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import "NSObject+Threading.h"


@implementation NSObject (Threading)

- (void)performBlockOnMainThread:(void (^)(void))block
{
	dispatch_async(dispatch_get_main_queue(), block);
}

- (void)performBlockInBackground:(void(^)(void))block
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

@end
