//
//  Network.h
//  Bolts+AFNetworking
//
//  Created by iamchiwon on 2016. 5. 19..
//  Copyright © 2016년 iamchiwon. All rights reserved.
//

#import "AFNetworking-umbrella.h"
#import "Bolts.h"
#import <UIKit/UIKit.h>

@interface Network : NSObject

+ (nonnull BFTask*)requestGET:(nonnull NSString*)url;

+ (nonnull BFTask*)requestPOST:(nonnull NSString*)url withParameter:(nullable NSDictionary*)params;

+ (BOOL)isWebImageCached:(nonnull NSString*)url;

+ (nonnull BFTask*)requestWebImage:(nonnull NSString*)url;

@end
