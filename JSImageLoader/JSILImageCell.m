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

- (void)setImageURL:(NSURL *)url
{
	if (_imageURL == url) return;
	_imageURL = url;
	
	self.imageView.image = nil;
	
	[[JSImageLoader sharedInstance] getImageAtURL:url completionHandler:^(NSError *error, UIImage *image, NSURL *imageURL, BOOL cached) {
		if (error == nil && self.imageURL == imageURL) {
			self.imageView.image = image;
		}
	}];
}

@end
