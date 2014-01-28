//
//  ImageCell.h
//  JSImageCache
//
//  Created by Jernej Strasner on 5/24/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JSILImageCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (nonatomic, strong) NSURL *imageURL;

@end
