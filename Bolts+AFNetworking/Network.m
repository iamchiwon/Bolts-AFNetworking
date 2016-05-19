//
//  Network.m
//  Bolts+AFNetworking
//
//  Created by iamchiwon on 2016. 5. 19..
//  Copyright © 2016년 iamchiwon. All rights reserved.
//

#import "Network.h"

@interface Network ()
@property NSCache* imageCache;
@end

@implementation Network

//싱글톤 : 이미지 캐시 인스턴스 생성용
+ (Network*)sharedNetwork
{
    static dispatch_once_t onceToken;
    static Network* sharedInstance;
    dispatch_once(&onceToken, ^{
        if (sharedInstance == nil)
            sharedInstance = [Network new];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.imageCache = [NSCache new];

        //메모리 부족할 때
        [[NSNotificationCenter defaultCenter] addObserverForName:
                                                  UIApplicationDidReceiveMemoryWarningNotification
                                                          object:[UIApplication sharedApplication]
                                                           queue:nil
                                                      usingBlock:^(NSNotification* notif) {
                                                          //캐시 없애기
                                                          self.imageCache = [NSCache new];
                                                      }];
    }
    return self;
}

+ (BFTask*)requestGET:(NSString*)url
{
    //결과를 확인하기 위한 Bolts 용 인스턴스 생성
    BFTaskCompletionSource* taskSource = [BFTaskCompletionSource taskCompletionSource];

    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];

    NSURLSessionConfiguration* configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager* manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    manager.responseSerializer = [AFJSONResponseSerializer serializer]; //리턴값은 JSON 으로 오는 것을 가정한다.

    NSURLSessionDataTask* dataTask = [manager dataTaskWithRequest:request
                                                completionHandler:^(NSURLResponse* _Nonnull response, id _Nullable responseObject, NSError* _Nullable error) {
                                                    if (error != nil) {
                                                        //Bolts 의 태스크에다가 에러를 기록한다.
                                                        [taskSource setError:error];
                                                    }
                                                    else {
                                                        //Bolts 의 태스크에다가 결과를 기록한다.
                                                        [taskSource setResult:(NSDictionary*)responseObject];
                                                    }
                                                }];
    [dataTask resume];

    //여기서 BFTask를 꺼내서 리턴한다.
    return taskSource.task;
}

+ (BFTask*)requestPOST:(NSString*)url withParameter:(NSDictionary*)params
{
    //결과를 확인하기 위한 Bolts 용 인스턴스 생성
    BFTaskCompletionSource* taskSource = [BFTaskCompletionSource taskCompletionSource];

    NSMutableURLRequest* request = [[AFJSONRequestSerializer serializer] requestWithMethod:@"POST"
                                                                                 URLString:url
                                                                                parameters:params
                                                                                     error:nil];

    NSURLSessionConfiguration* configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager* manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    manager.responseSerializer = [AFJSONResponseSerializer serializer]; //리턴값은 JSON 으로 오는 것을 가정한다.

    NSURLSessionDataTask* dataTask = [manager dataTaskWithRequest:request
                                                completionHandler:^(NSURLResponse* _Nonnull response, id _Nullable responseObject, NSError* _Nullable error) {
                                                    if (error != nil) {
                                                        //Bolts 의 태스크에다가 에러를 기록한다.
                                                        [taskSource setError:error];
                                                    }
                                                    else {
                                                        //Bolts 의 태스크에다가 결과를 기록한다.
                                                        [taskSource setResult:(NSDictionary*)responseObject];
                                                    }
                                                }];
    [dataTask resume];

    //여기서 BFTask를 꺼내서 리턴한다.
    return taskSource.task;
}

+ (BOOL)isWebImageCached:(NSString*)url
{
    Network* network = [Network sharedNetwork];
    id imageData = [network.imageCache objectForKey:url];
    if (imageData != nil) {
        return YES;
    }
    return NO;
}

+ (BFTask*)requestWebImage:(NSString*)url
{
    //결과를 확인하기 위한 Bolts 용 인스턴스 생성
    BFTaskCompletionSource* taskSource = [BFTaskCompletionSource taskCompletionSource];

    Network* network = [Network sharedNetwork];
    //먼저 캐시에서 찾아본다.
    id imageData = [network.imageCache objectForKey:url];
    if (imageData != nil) {
        //캐시에서 찾으면 바로 결과를 기록한다.
        [taskSource setResult:imageData];
    }
    else {
        NSURLSessionConfiguration* configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        AFURLSessionManager* manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
        manager.responseSerializer = [AFImageResponseSerializer serializer]; //결과를 이미지로 받아온다.

        NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        NSURLSessionDataTask* dataTask = [manager dataTaskWithRequest:request
                                                    completionHandler:^(NSURLResponse* _Nonnull response, id _Nullable responseObject, NSError* _Nullable error) {
                                                        if (error != nil) {
                                                            //에러를 기록한다.
                                                            [taskSource setError:error];
                                                        }
                                                        else {
                                                            //이미지를 캐싱한다.
                                                            [network.imageCache setObject:responseObject forKey:url];
                                                            //결과를 기록한다.
                                                            [taskSource setResult:responseObject];
                                                        }
                                                    }];
        [dataTask resume];
    }

    //태스크를 꺼내서 리턴한다.
    return taskSource.task;
}

@end
