//
//  ViewController.m
//  Bolts+AFNetworking
//
//  Created by iamchiwon on 2016. 5. 19..
//  Copyright © 2016년 iamchiwon. All rights reserved.
//

#import "MBProgressHUD.h"
#import "Network.h"
#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView* imageView;
@property (weak, nonatomic) IBOutlet UITextView* textArea;
@property (weak, nonatomic) IBOutlet UISwitch* progressShowingSwitch;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onShowImage:(UIButton*)sender
{
    NSArray* imageURLs = @[
        @"https://i.ytimg.com/vi/C5qga40BbWo/maxresdefault.jpg",
        @"https://haruka.namuwikiusercontent.com/26/269fd4f36de0c343041cdd936f9d19623cf605ab188584f7ea2e4219d5f558d7.jpg",
        @"https://66.media.tumblr.com/482438b6d8c6aa9ef19d3ca12e10d9dc/tumblr_nt7kvaQoE71uouiteo1_500.png"
    ];

    NSInteger index = sender.tag;

    //이미지 요청
    BFTask* task = [Network requestWebImage:imageURLs[index]];

    //프로그래스 띄우기
    if (self.progressShowingSwitch.isOn && ![Network isWebImageCached:imageURLs[index]]) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }

    //요청 결과가 오면 처리할 블록 (언젠 나중에 불린다.)
    [task continueWithBlock:^id _Nullable(BFTask* _Nonnull task) {
        //네트워크 결과가 왔다.

        //프로그래스 없애기
        if (self.progressShowingSwitch.isOn) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }

        //에러처리
        if (task.error != nil) {
            NSLog(@"%@", [task.error localizedDescription]);
            return task;
        }

        //결과 이미지 세팅하기
        UIImage* image = task.result; //결과는 UIImage* 형태이다.
        self.imageView.image = image;

        //파라미터로 받은 task를 리턴한다.
        return task;
    }];
}

- (IBAction)onGetData:(id)sender
{
    NSString* urlforGET = @"http://www.kobis.or.kr/kobisopenapi/webservice/rest/boxoffice/searchDailyBoxOfficeList.json?key=430156241533f1d058c603178cc3ca0e&targetDt=20120101";

    //프로그래스 띄우기
    if (self.progressShowingSwitch.isOn) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }

    self.textArea.text = @"";

    BFTask* task = [Network requestGET:urlforGET];
    [[[task continueWithBlock:^id _Nullable(BFTask* _Nonnull task) {

        //프로그래스 없애기
        if (self.progressShowingSwitch.isOn) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }

        //에러처리
        if (task.error != nil) {
            NSLog(@"%@", [task.error localizedDescription]);
            return task;
        }

        //데이터 처리를 여기서 해도 되는데 그냥 다음으로 념겨 본다 (에제니까)
        return task;

    }] continueWithBlock:^id _Nullable(BFTask* _Nonnull task) {

        /* 데이터 파싱 */

        //위의 task 가 그대로 내려오니가 result 가 유지된다.
        //result 는 json이 파싱된 dictionary 이다.
        NSDictionary* jsonData = task.result;

        NSDictionary* movieData = jsonData[@"boxOfficeResult"];
        NSMutableString* resultText = [NSMutableString new];

        //title
        [resultText appendFormat:@"** %@ **\n\n", movieData[@"boxofficeType"]];
        //movies
        NSArray* movies = movieData[@"dailyBoxOfficeList"];
        for (NSDictionary* movie in movies) {
            [resultText appendString:@"----------------\n"];
            [resultText appendFormat:@"  제목:%@\n", movie[@"movieNm"]];
            [resultText appendFormat:@"  개봉일:%@\n", movie[@"openDt"]];
        }

        //피싱된 결과를 다음 태스크로 보낸다. (예제니까)
        //태스크를 새로 만들고 결과를 입력한 다음에 그 놈을 리턴한다.
        BFTask* newTask = [BFTask taskWithResult:resultText];
        return newTask;

        /*
         여기서는 continue 블럭에 Executor 를 달았다. UI에 세팅하는 부분이니까
         mainThread 에서 실행되도록 지정하는 것이다. (굳이 이렇게까지 할 필요 없지만.. 예제니까)
        */
    }] continueWithExecutor:[BFExecutor mainThreadExecutor]
                   withBlock:^id _Nullable(BFTask* _Nonnull task) {

                       /* 데이터 세팅하기 */

                       //위에서 파싱결과를 담은 task 를 받았다. 그 결과를 UI에 세팅한다.
                       self.textArea.text = task.result;

                       return task;
                   }];
}

@end
