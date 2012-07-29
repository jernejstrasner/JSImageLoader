//
//  ImageCell.m
//  JSImageCache
//
//  Created by Jernej Strasner on 5/24/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import "ImageCell.h"


@implementation ImageCell

#pragma mark - Properties

@synthesize imageView;
@synthesize imageURL = _imageURL;

- (void)setImageURL:(NSURL *)url
{
	[_imageURL release];
	_imageURL = [url retain];
	
	self.imageView.image = nil;
	
	[[JSImageLoader sharedInstance] getImageAtURL:url completionHandler:^(NSError *error, UIImage *image, NSURL *imageURL) {
		if (error == nil && self.imageURL == imageURL) {
			self.imageView.image = image;
		}
	}];
}

#pragma mark - Initialization

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
		imageView = [[UIImageView alloc] init];
		imageView.contentMode = UIViewContentModeScaleAspectFill;
		imageView.clipsToBounds = YES;
		[self.contentView addSubview:imageView];
    }
    return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	self.imageView.frame = CGRectMake(5.0f, 5.0f, 54.0f, 54.0f);
	self.textLabel.frame = CGRectMake(64.0f, 5.0f, 251.0f, 54.0f);
}

#pragma mark - Memory management

- (void)dealloc
{
	[imageView release];
    [super dealloc];
}

@end
