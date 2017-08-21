//
//  ViewController.m
//  GCDDemo
//
//  Created by 张佳 on 2017/8/15.
//  Copyright © 2017年 张佳. All rights reserved.
//

#import "ViewController.h"

#define KDouBanURL  @"https://api.douban.com/v2/movie/in_theaters?apikey=0b2bdeda43b5688921839c8ecb20399b&city=%E5%8C%97%E4%BA%AC&start=0&count=100&client=somemessage&udid=dddddddddddddddddddddd"

#define KWeatherURL @"https://weatherapi.market.xiaomi.com/wtr-v3/weather/all?latitude=110&longitude=112&isLocated=true&locationKey=weathercn%3A101010100&days=15&appKey=weather20151024&sign=zUFJoAR2ZVrDy1vF3D07&romVersion=7.2.16&appVersion=87&alpha=false&isGlobal=false&device=cancro&modDevice=&locale=zh_cn"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//通过dispatch group实现多个请求并发，都完成后回调
- (IBAction)serialQueueRequest:(id)sender {
    dispatch_group_t dispatchGroup = dispatch_group_create();
    
    dispatch_group_enter(dispatchGroup);
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithURL:[NSURL URLWithString:KDouBanURL] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"got data from internet1");
        dispatch_group_leave(dispatchGroup);
    }];
    [task resume];
    
    dispatch_group_enter(dispatchGroup);
    NSURLSessionDataTask *task2 = [session dataTaskWithURL:[NSURL URLWithString:KWeatherURL] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"got data from internet2");
        dispatch_group_leave(dispatchGroup);
    }];
    [task2 resume];
    
    dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^(){
        NSLog(@"end");
    });
    
}

//通过dispatch group和dispatch semaphore信号量 实现指定最大并发数的多任务请求
- (IBAction)downloadGroup:(id)sender {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(3);
    
    dispatch_group_t dispatchGroup = dispatch_group_create();
    
    NSArray *urlArray = @[@"https://freemacsoft.net/downloads/AppCleaner_3.4.zip",
                          @"https://freemacsoft.net/downloads/AppCleaner_3.4.zip",
                          @"https://freemacsoft.net/downloads/AppCleaner_3.4.zip",
                          @"https://freemacsoft.net/downloads/AppCleaner_3.4.zip",
                          @"https://freemacsoft.net/downloads/AppCleaner_3.4.zip",
                          @"https://freemacsoft.net/downloads/AppCleaner_3.4.zip"];
    for (int i = 0; i < urlArray.count; i++) {
        
        NSLog(@"i is %d",i);
        NSURLSession *session = [NSURLSession sharedSession];
        
        NSURL *url = [NSURL URLWithString:urlArray[i]];
        
        NSURLSessionDownloadTask *sessionDownloadTask =[session downloadTaskWithURL:url completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            sleep(5.0);
            
            NSLog(@"release a signal");
            
            dispatch_group_leave(dispatchGroup);
            dispatch_semaphore_signal(semaphore);
            
            
        }];
        
        dispatch_group_enter(dispatchGroup);//为了所有下载完成后能调用函数，引入 dispatch group。如果信号量是1的话，可以不使用这个机制，也能达到效果。
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER); //为了最大并发数，加入信号量机制
        
        [sessionDownloadTask resume];
        
    }
    
    dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^(){
        NSLog(@"all download finish");
    });
}

//通过NSOperationQueue 和dispatch semaphore 及kvo 实现对多个异步请求串行执行并监听
- (IBAction)serialSemaphore:(id)sender {
    
    NSBlockOperation *operation1 = [NSBlockOperation blockOperationWithBlock:^{
        [self requestOperation1];
    }];
    NSBlockOperation *operation2 = [NSBlockOperation blockOperationWithBlock:^{
        [self requestOperation2];
    }];
    NSBlockOperation *operation3 = [NSBlockOperation blockOperationWithBlock:^{
        [self requestOperation3];
    }];
    [operation2 addDependency:operation1]; //任务二依赖任务一
    [operation3 addDependency:operation2]; //任务三依赖任务二
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperations:@[operation3, operation2, operation1] waitUntilFinished:NO];
    [queue addObserver:self forKeyPath:@"operationCount" options:0 context:nil];
}

- (void)requestOperation1 {
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *task = [session dataTaskWithURL:[NSURL URLWithString:KDouBanURL] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"got data from internet1");
        dispatch_semaphore_signal(semaphore);
    }];
    [task resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

- (void)requestOperation2 {
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *task = [session dataTaskWithURL:[NSURL URLWithString:KWeatherURL] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"got data from internet2");
        dispatch_semaphore_signal(semaphore);
    }];
    [task resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

- (void)requestOperation3 {
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *task = [session dataTaskWithURL:[NSURL URLWithString:KDouBanURL] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"got data from internet3");
        dispatch_semaphore_signal(semaphore);
    }];
    [task resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

//添加监听 监听队列是否全部执行完毕
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"operationCount"]) {
        NSOperationQueue *queue = (NSOperationQueue *)object;
        if (queue.operationCount == 0) {
            NSLog(@"全部完成");
        }
    }
}

//通过dispatch queue 和dispatch semaphore 实现多个异步请求串行执行
- (IBAction)serialGroupCallBack:(id)sender {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    dispatch_queue_t queue = dispatch_queue_create("com.gameDemo.serialTask", DISPATCH_QUEUE_SERIAL);
    
    dispatch_async( queue, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);//信号量 -1
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithURL:[NSURL URLWithString:KDouBanURL] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSLog(@"got data from internet1");
            dispatch_semaphore_signal(semaphore); //信号量 +1
        }];
        [task resume];

    });
    
    
    dispatch_async(queue, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithURL:[NSURL URLWithString:KWeatherURL] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSLog(@"got data from internet2");
            dispatch_semaphore_signal(semaphore);
        }];
        [task resume];
    });
    
    
    dispatch_async(queue, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithURL:[NSURL URLWithString:KDouBanURL] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSLog(@"got data from internet3");
            dispatch_semaphore_signal(semaphore);
        }];
        [task resume];
    });
    
    
    dispatch_async(queue, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"queue all finish");
        
        dispatch_semaphore_signal(semaphore);
    });
}
@end
