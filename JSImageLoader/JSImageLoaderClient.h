/*
 Copyright (c) 2011 Jernej Strasner
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software
 and associated documentation files (the "Software"), to deal in the Software without restriction,
 including without limitation the rights to use, copy, modify, merge, publish, distribute,
 sublicense, and/or sell copies of the Software, and to permit persons to whom the Software
 is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or
 substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
 PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
 FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 
 */
//
//  CachedImageClient.h
//  JSImageCache
//
//  Created by Jernej Strasner on 12/19/10.
//  Copyright 2010 JernejStrasner.com. All rights reserved.
//
//  This is the client object
//  It retains the request, so if the original target object changes the request, we still have the original one
//  It is used in conjunction with the method renderImage:withRequest:
//  It is usefull with table views or other views where the cells (or other objects) get reused


#import <Foundation/Foundation.h>


@interface JSImageLoaderClient : NSObject {
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
