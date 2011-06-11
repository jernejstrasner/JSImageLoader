//
//  ImageCell.h
//  JSImageCache
//
//  Created by Jernej Strasner on 5/24/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "JSImageLoader.h"

@interface ImageCell : UITableViewCell <CachedImageDelegate> {
    JSImageLoader *imageLoader;
	JSImageLoaderClient *imageClient;
	
	NSString *imageURL;
	
	UIImageView *imageView;
}

@property (nonatomic, assign) JSImageLoader *imageLoader;

@property (nonatomic, retain) NSString *imageURL;

@property (nonatomic, readonly, retain) UIImageView *imageView;

@end
