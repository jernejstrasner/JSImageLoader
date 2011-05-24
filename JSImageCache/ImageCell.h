//
//  ImageCell.h
//  JSImageCache
//
//  Created by Jernej Strasner on 5/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CachedImageLoader.h"

@interface ImageCell : UITableViewCell <CachedImageConsumer> {
    CachedImageLoader *imageLoader;
	CachedImageClient *imageClient;
	
	NSString *imageURL;
	
	UIImageView *imageView;
}

@property (nonatomic, assign) CachedImageLoader *imageLoader;

@property (nonatomic, retain) NSString *imageURL;

@property (nonatomic, readonly, retain) UIImageView *imageView;

@end
