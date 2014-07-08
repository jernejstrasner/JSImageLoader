//
//  MainViewController.swift
//  JSImageLoader
//
//  Created by Jernej Strasner on 6/27/14.
//
//

import UIKit

class MainViewController: UICollectionViewController {
	
	let tags = ["ocean", "stanford", "tropic", "slovenia"]
	var data = NSArray()
	
	override func prefersStatusBarHidden() -> Bool  {
		return true
	}

    override func viewDidLoad() {
        super.viewDidLoad()

		// Set a custom cache size
		ImageLoaderCache.sharedCache.cacheSize = 1024*2000
		
		// Load some test data from Flickr
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
			
			var receivedItems = NSMutableArray()
			for tag in self.tags {
				// Generate URL for tag
				let url = NSURL(string: "http://api.flickr.com/services/feeds/photos_public.gne?format=json&tags=\(tag)")
				// Fetch data
				var json = NSMutableString(contentsOfURL: url, encoding: NSUTF8StringEncoding, error: nil)
				// Remove the JSONP function wrapper
				json.replaceCharactersInRange(NSMakeRange(0, 15), withString: "")
				json.replaceCharactersInRange(NSMakeRange(json.length-1, 1), withString: "")
				json.replaceOccurrencesOfString("\\'", withString: "'", options: nil, range: NSMakeRange(0, json.length))
				// Parse JSON
				let obj: AnyObject! = NSJSONSerialization.JSONObjectWithData(json.dataUsingEncoding(NSUTF8StringEncoding),
					options: NSJSONReadingOptions.AllowFragments,
					error: nil)
				
				if obj {
					// Add to results
					receivedItems.addObjectsFromArray(obj.valueForKey("items") as NSArray)
				}
				else {
					println("Error loading flicker images for tag '\(tag)")
				}
			}
			
			dispatch_async(dispatch_get_main_queue()) {
				self.data = NSArray(array: receivedItems)
				self.collectionView.reloadData()
			}
		}
    }
	
	// Collection View
	
	override func numberOfSectionsInCollectionView(collectionView: UICollectionView!) -> Int {
		return 1
	}
	
	override func collectionView(collectionView: UICollectionView!, numberOfItemsInSection section: Int) -> Int {
		return data.count
	}
	
	override func collectionView(collectionView: UICollectionView!, cellForItemAtIndexPath indexPath: NSIndexPath!) -> UICollectionViewCell! {
		let cell = collectionView?.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as ImageCell!
		if cell {
			let itm = data[indexPath.item] as? NSDictionary
			let url: AnyObject? = itm?.valueForKeyPath("media.m")
			cell.imageURL = NSURL(string: url as? String)
		}
		return cell
	}

}
