//
//  ImageCell.m
//  JSImageCache
//
//  Created by Jernej Strasner on 5/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ImageCell.h"


@implementation ImageCell

#pragma mark - Properties

@synthesize imageLoader;

@synthesize imageURL;

- (void)setImageURL:(NSString *)url {
	[imageURL release];
	imageURL = [url retain];
	
	// Clear any existing image
	self.imageView.image = nil;
	
	// Cancel any previous image fetches for this cell
	[imageClient cancelFetch];
	imageClient.client = nil;
	[imageClient release];
	
	// Create a new client object
	imageClient = [[JSImageLoaderClient alloc] init];
	imageClient.request = [NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15.0];
	imageClient.client = self;
	// Start the image fetch
	[imageLoader addClientToDownloadQueue:imageClient];
}

@synthesize imageView;

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

- (void)layoutSubviews {
	[super layoutSubviews];
	imageView.frame = CGRectMake(5.0f, 5.0f, 54.0f, 54.0f);
	self.textLabel.frame = CGRectMake(64.0f, 5.0f, 251.0f, 54.0f);
}

#pragma mark - CachedImageConsumer

- (void)renderImage:(UIImage *)image forClient:(JSImageLoaderClient *)client {
	// Check if the request is coming from the right client
	if (client == imageClient) {
		// Render the image
		self.imageView.image = image;
	}
}

#pragma mark - Memory management

- (void)dealloc
{
	[imageClient cancelFetch];
	imageClient.client = nil;
	[imageClient release];
	
	[imageLoader release];
	
	[imageView release];
	
    [super dealloc];
}

@end
