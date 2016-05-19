# Bolts+AFNetworking


iOS 에서 AFNetworking 을 사용해서 서버 연동하는 것과 <br/>
Bolts로 컨트롤 하는 것을 보여주는 예제 소스 입니다.<br/>
( 이 예제는 **Objective-C** 소스입니다. )

- [AFNetworking](https://github.com/AFNetworking/AFNetworking)
- [Bolts-ObjC](https://github.com/BoltsFramework/Bolts-ObjC)

---


## AFNetworking

#### AFNetworking 으로 GET 요청하기.<br/>
*AFJSONResponseSerializer* 를 사용하여 받아온 결과는 파싱된 NSDictionary 형태로 전달된다.

```objective-c
NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];

NSURLSessionConfiguration* configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
AFURLSessionManager* manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
manager.responseSerializer = [AFJSONResponseSerializer serializer]; //리턴값은 JSON 으로 오는 것을 가정한다.

NSURLSessionDataTask* dataTask = [manager dataTaskWithRequest:request
                                            completionHandler:^(NSURLResponse* _Nonnull response, id _Nullable responseObject, NSError* _Nullable error) {
                                                if (error != nil) {
                                                    //에러처리
                                                }
                                                else {
                                                    //결과 받기
                                                }
                                            }];
```

#### Bolts 에 태우기

ASync 하게 네트워크를 사용한 후 결과를 serial 하게 처리하기 위해서 Bolts에 태운다. 그러기 위해서는 network 처리 코드는 **BFTask** 를 반환하도록 작성한다.

```objective-c
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
```

1. 네트워크를 처리하는 메소드가 호출되면 AFNetworking 에 의해서 쓰레드로 돌고 결과를 바로 반환된다. 여기에 BFTask 를 리턴하도록 한다.
2. 이 BFTask 에다가 결과를 전달하기 위해서 BFTaskCompletionSource 를 만들어서 사용한다.
3. 네트워크 연동 결과의 block 에서 이 CompletionSource 에다가 결과를 담는다.
4. error 나 result 가 담기게 되면 이 BFTask 가 완료 되는 것이고, 이 task 를 사용한 측의 continueBlock 이 이어서 호출된다.


---

## Bolts

```objective-c
- (IBAction)onGetData:(id)sender
{
    NSString* urlforGET = @"http://www.kobis.or.kr/kobisopenapi/webservice/rest/boxoffice/searchDailyBoxOfficeList.json?key=430156241533f1d058c603178cc3ca0e&targetDt=20120101";

    BFTask* task = [Network requestGET:urlforGET];
    [[[task continueWithBlock:^id _Nullable(BFTask* _Nonnull task) {

        //에러처리
        if (task.error != nil) {
            return task;
        }

        //데이터 처리를 여기서 해도 되는데 그냥 다음으로 념겨 본다 (에제니까)
        return task;

    }] continueWithBlock:^id _Nullable(BFTask* _Nonnull task) {

        /* 데이터 파싱 (생략) */
        BFTask* newTask = [BFTask taskWithResult:parsedData];
        return newTask;

        /*
         여기서는 continue 블럭에 Executor 를 달았다. UI에 세팅하는 부분이니까
         mainThread 에서 실행되도록 지정하는 것이다. (굳이 이렇게까지 할 필요 없지만.. 예제니까)
        */
    }] continueWithExecutor:[BFExecutor mainThreadExecutor]
                   withBlock:^id _Nullable(BFTask* _Nonnull task) {

                       //위에서 파싱결과를 담은 task 를 받았다. 그 결과를 UI에 세팅한다.
                       self.textArea.text = task.result;

                       return task;
                   }];
}
```

1. 네트워크 연동 요청을 하고 BFTask 를 전달 받는다.
2. 여기에다가  continueBlock 을 걸고 전달된 결과값을 처리한다.
3. continueBlock 을 연달아 사용하면서 task 내의 전달값을 바꾸며 진행할 수 있다.
3. UI Thread 에서 돌릴 필요가 있는 부분은 BFExecutor 를 사용해서 지정할 수 있다.

---

## Network.h/.m

예제 소스에서 Network 클래스에서 그 사용 예제를 다 보여주고 있다.<br/>
그 외에 참고할 만한 부분은 이렇다.

#### AFImageResponseSerializer

AFNetworking  을 사용할 때 AFImageResponseSerializer 를 사용하면 결과값이 UIImage 로 전달된다.

#### NSCache

캐시 기능이 필요할 때 간단히 사용할 수 있다. 그냥 NSDictionary 처럼 사용하면 된다.
*UIApplicationDidReceiveMemoryWarningNotification* 이 발생했을 때 이 NSCache 를 비워준다.
```objective-c
        //메모리 부족할 때
        [[NSNotificationCenter defaultCenter] addObserverForName:
                                                  UIApplicationDidReceiveMemoryWarningNotification
                                                          object:[UIApplication sharedApplication]
                                                           queue:nil
                                                      usingBlock:^(NSNotification* notif) {
                                                          //캐시 없애기
                                                          self.imageCache = [NSCache new];
                                                      }];

```

---

# 기타 사항

#### iOS 9 의 Transport Security
```xml
//Info.plist
    <key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsArbitraryLoads</key>
		<true/>
	</dict>
```

#### 사용하는 Pod
```
  pod 'AFNetworking'
  pod 'Bolts'
  pod 'MBProgressHUD'
```