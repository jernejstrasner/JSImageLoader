//
//  NSString-Crypto.h
//  Facebook
//
//  Created by Jernej Strasner on 11/21/10.
//  Copyright 2010 JernejStrasner.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>

@interface NSString (Crypto)

- (NSString *)md5;

@end
