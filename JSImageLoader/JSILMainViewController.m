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
//  RootViewController.m
//  JSImageCache
//
//  Created by Jernej Strasner on 5/23/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import "JSILMainViewController.h"

#import "NSObject+Threading.h"

#import "JSILImageCell.h"

@implementation JSILMainViewController {
	NSArray *data;
}

- (BOOL)prefersStatusBarHidden
{
	return YES;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	[self performBlockInBackground:^(void) {
		NSArray *tags = @[@"ocean", @"stanford", @"tropic", @"mexico"];
		NSMutableArray *receivedItems = [[NSMutableArray alloc] init];
		for (NSString *tag in tags) {
			NSString *urlString = [NSString stringWithFormat:@"http://api.flickr.com/services/feeds/photos_public.gne?format=json&tags=%@", tag];
			NSString *jsonString = [NSString stringWithContentsOfURL:[NSURL URLWithString:urlString]
															encoding:NSUTF8StringEncoding
															   error:nil];
			// Fix the invalid flickr JSON
			jsonString = [jsonString stringByReplacingCharactersInRange:NSMakeRange(0, 15) withString:@""];
			jsonString = [jsonString stringByReplacingCharactersInRange:NSMakeRange([jsonString length]-1, 1) withString:@""];
			jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\\'" withString:@"'"];
			
			// Create an object from the JSON
			NSError *error;
			NSDictionary *obj = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];

			if (!error) {
				[receivedItems addObjectsFromArray:[obj valueForKey:@"items"]];
			}
			else {
				NSLog(@"%@", [error localizedDescription]);
			}
		}
		
		[self performBlockOnMainThread:^{
			data = [NSArray arrayWithArray:receivedItems];
			[self.collectionView reloadData];
		}];
	}];
}

- (void)dealloc
{
	[[JSImageLoader sharedInstance] cancelImageDownloads];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
	return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return data.count;
}

// Customize the appearance of table view cells.
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSILImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];

	NSDictionary *obj = data[indexPath.row];
	cell.imageURL = [NSURL URLWithString:[obj valueForKeyPath:@"media.m"]];
	
    return cell;
}

@end
