//
//  CachedImageClient.h
//  Facebook
//
//  Created by Jernej Strasner on 12/19/10.
//  Copyright 2010 JernejStrasner.com. All rights reserved.
//
//  This is the client object
//  It retains the request, so if the original target object changes the request, we still have the original one
//  It is used in conjunction with the method renderImage:withRequest:
//  It is usefull with table views or other views where the cells (or other objects) get reused


#import <Foundation/Foundation.h>


@interface CachedImageClient : NSObject {
	id client;
	NSURLRequest *request;
	NSUInteger retries;
	NSOperation *fetchOperation;
}

@property (nonatomic, assign) id client;
@property (nonatomic, retain) NSURLRequest *request;
@property (nonatomic, assign) NSUInteger retries;
@property (nonatomic, retain) NSOperation *fetchOperation;

- (void)cancelFetch;

@end
