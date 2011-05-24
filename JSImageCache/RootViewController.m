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

#import "RootViewController.h"

#import "NSObject+Threading.h"
#import "JSONKit.h"

#import "ImageCell.h"

@implementation RootViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"Flickr";
	
	self.tableView.rowHeight = 64.0f;
	
	if (!cachedImageLoader) {
		cachedImageLoader = [[CachedImageLoader alloc] init];
	}
	
	[self performBlockInBackground:^(void) {
		NSString *jsonString = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://api.flickr.com/services/feeds/photos_public.gne?format=json"] encoding:NSUTF8StringEncoding error:nil];
		// Fix the invalid flickr JSON
		jsonString = [jsonString stringByReplacingCharactersInRange:NSMakeRange(0, 15) withString:@""];
		jsonString = [jsonString stringByReplacingCharactersInRange:NSMakeRange([jsonString length]-1, 1) withString:@""];
		jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\\'" withString:@"'"];
		// Create an object from the JSON
		NSError *error = nil;
		NSDictionary *obj = [jsonString objectFromJSONStringWithParseOptions:0 error:&error];
		NSLog(@"%@", obj);
		if (error == nil) {
			[self performBlockOnMainThread:^(void) {
				data = [[obj valueForKey:@"items"] retain];
				[self.tableView reloadData];
			}];
		} else {
			NSLog(@"%@", [error localizedDescription]);
		}
	}];
}

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [data count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    ImageCell *cell = (ImageCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[ImageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

	NSDictionary *obj = [data objectAtIndex:indexPath.row];
	cell.imageLoader = cachedImageLoader;
	cell.imageURL = [obj valueForKeyPath:@"media.m"];
	cell.textLabel.text = [obj valueForKey:@"title"];
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}

- (void)dealloc
{
	[data release];
	[cachedImageLoader cancelImageDownloads];
	[cachedImageLoader release];
    [super dealloc];
}

@end
