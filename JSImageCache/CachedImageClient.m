//
//  CachedImageClient.m
//  Facebook
//
//  Created by Jernej Strasner on 12/19/10.
//  Copyright 2010 JernejStrasner.com. All rights reserved.
//

#import "CachedImageClient.h"


@implementation CachedImageClient

@synthesize client;
@synthesize request;
@synthesize retries;
@synthesize fetchOperation;

- (id)init {
	self = [super init];
	if (self) {
		retries = 0;
	}
	return self;
}

- (void)cancelFetch {
	[fetchOperation cancel];
}

- (void)dealloc {
	[request release];
	[fetchOperation release];
	[super dealloc];
}

@end
