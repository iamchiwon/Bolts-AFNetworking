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

+ (BFTask*)requestGET:(NSString*)url;

+ (BFTask*)requestPOST:(NSString*)url withParameter:(NSDictionary*)params;

+ (BOOL)isWebImageCached:(NSString*)url;

+ (BFTask*)requestWebImage:(NSString*)url;

@end
