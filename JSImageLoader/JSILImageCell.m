//
//  ImageCell.m
//  JSImageCache
//
//  Created by Jernej Strasner on 5/24/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import "JSILImageCell.h"

#import "JSImageLoader.h"

@implementation JSILImageCell

- (void)prepareForReuse
{
	[super prepareForReuse];
	
	_imageView.image = nil;
	_imageURL = nil;
}

- (void)setImageURL:(NSURL *)url
{
	if ([_imageURL isEqual:url]) return;
	_imageURL = url;
	
	__weak __typeof__(self) weakSelf = self;
	[[JSImageLoader sharedInstance] getImageAtURL:url completionHandler:^(NSError *error, UIImage *image, NSURL *imageURL, BOOL cached) {
		__typeof__(self) strongSelf = weakSelf;
		if (image && [strongSelf.imageURL isEqual:imageURL]) {
			strongSelf.imageView.image = image;
		}
	}];
}

@end
