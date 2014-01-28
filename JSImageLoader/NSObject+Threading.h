//
//  NSObject+Threading.h
//  FollowTheFace
//
//  Created by Jernej Strasner on 4/30/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (JSILThreading)

- (void)performBlockOnMainThread:(void(^)(void))block;
- (void)performBlockInBackground:(void(^)(void))block;

@end
