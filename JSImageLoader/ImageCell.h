//
//  ImageCell.h
//  JSImageCache
//
//  Created by Jernej Strasner on 5/24/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "JSImageLoader.h"

@interface ImageCell : UITableViewCell

@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, readonly) UIImageView *imageView;

@end
