//
//  YYWebSocketManager.m
//  CloseRange
//
//  Created by 韩亚周 on 2019/6/15.
//  Copyright © 2019 韩亚周. All rights reserved.
//
#define dispatch_main_async_safe(block)\
if ([NSThread isMainThread]) {\
    block();\
} else {\
    dispatch_async(dispatch_get_main_queue(), block);\
}
#import "YYWebSocketManager.h"

@interface YYWebSocketManager ()

//心跳定时器
@property (nonatomic, strong) NSTimer *heartBeatTimer;
//没有网络的时候检测网络定时器
@property (nonatomic, strong) NSTimer *netWorkTestingTimer;
//重连时间
@property (nonatomic, assign) NSTimeInterval reConnectTime;
//存储要发送给服务端的数据
@property (nonatomic, strong) NSMutableArray *sendDataArray;
//用于判断是否主动关闭长连接，如果是主动断开连接，连接失败的代理中，就不用执行 重新连接方法
@property (nonatomic, assign) BOOL isActivelyClose;

@end

@implementation YYWebSocketManager

+(instancetype)shared{
    static YYWebSocketManager *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc]init];
    });
    return _instance;
}

- (instancetype)init
{
    self = [super init];
    if(self){
        self.reConnectTime = 0;
        self.isActivelyClose = NO;
        
        self.sendDataArray = [[NSMutableArray alloc] init];
        
    }
    return self;
}

//建立长连接
- (void)connectServer{
    self.isActivelyClose = NO;
    
    self.webSocket.delegate = nil;
    [self.webSocket close];
    _webSocket = nil;
    //   Bearer  self.webSocket = [[RMWebSocket alloc] initWithURL:[NSURL URLWithString:@"https://dev-im-gateway.runxsports.com/ws/token=88888888"]];
    NSString * token  = @"xxx";
    
    NSString * url = @"xxxxx";
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    [request setValue:token forHTTPHeaderField:@"Authorization"];
    [request setValue:@"Content-Type" forHTTPHeaderField:@"application/json"];
    self.webSocket = [[SRWebSocket alloc] initWithURLRequest:request];
    self.webSocket.delegate = self;
    [self.webSocket open];
}

- (void)sendPing:(id)sender{
    NSData *data= [NSJSONSerialization dataWithJSONObject:@{@"action":@"HEARTBEAT"} options:NSJSONWritingPrettyPrinted error:nil];
    [self.webSocket sendPing:data];
    
//    NSArray *array = [NSArray arrayWithObjects:@"您好我现在有事儿不在稍后与您联系，【自动回复】！",
//                      @"通知：今天加班不？",
//                      @"小伙子加班班",@"6🐶8？",
//                      @"666",
//                      @"走",
//                      @"晚上去吃兴隆热干面吧，10块钱两碗，新店开业", nil];
//    
//    //1059368202278273024
//    NSData *data1= [NSJSONSerialization dataWithJSONObject:@{@"action": @"message",
//                                                             @"data": @{@"action": @"message",
//                                                                        @"userId":@"1059694244402561024",
//                                                                        @"toUserId": @"1059368202278273024",
//                                                                        @"toUserNickName":@"萱落",                            @"toUserAvatarUrl":@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1560749309358&di=e4c03b3ba052378fefebe695ce5b8552&imgtype=0&src=http%3A%2F%2Fi9.hexunimg.cn%2F2013-07-05%2F155842064.jpg",
//                                                                        @"content": array[arc4random()%6],
//                                                                        @"contentType": @0,
//                                                                        @"type": @1,
//                                                                        @"createTime": @"1532356521000"}
//                                                             } options:NSJSONWritingPrettyPrinted error:nil];
//    NSString *dataStr = [[NSString alloc] initWithData:data1 encoding:NSUTF8StringEncoding];
//    [self.webSocket send:dataStr];
}

#pragma mark --------------------------------------------------
#pragma mark - socket delegate
///开始连接
-(void)webSocketDidOpen:(SRWebSocket *)webSocket{
//    DLog(@"socket 开始连接");
    NSLog(@"socket 开始连接");
    NSLog(@"%@",webSocket);
    self.isConnect = YES;
    self.connectType = YYWebSocketConnect;
    [self initHeartBeat];///开始心跳
    if (webSocket == self.webSocket) {
        NSLog(@"************************** socket 连接成功************************** ");
      }
}

///连接失败
-(void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error{
    NSLog(@"%@",error);
//    DLog(@"连接失败");
    self.isConnect = NO;
    self.connectType = YYWebSocketDisconnect;
    
//    DLog(@"连接失败，这里可以实现掉线自动重连，要注意以下几点");
//    DLog(@"1.判断当前网络环境，如果断网了就不要连了，等待网络到来，在发起重连");
//    DLog(@"3.连接次数限制，如果连接失败了，重试10次左右就可以了");
    //判断网络环境
    if (AFNetworkReachabilityManager.sharedManager.networkReachabilityStatus == AFNetworkReachabilityStatusNotReachable){ //没有网络
        
        [self noNetWorkStartTestingTimer];//开启网络检测定时器
    }else{ //有网络
        
        [self reConnectServer];//连接失败就重连
    }
}

///接收消息
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
//    DLog(@"接收消息----  %@",message);
    if (_webSocketManagerDidReceiveMessage) {
        _webSocketManagerDidReceiveMessage(message);
    }
}


///关闭连接
-(void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean{
    self.isConnect = NO;
    if(self.isActivelyClose){
        self.connectType = YYWebSocketDefault;
        return;
    }else{
        self.connectType = YYWebSocketDisconnect;
    }
    
//    DLog(@"被关闭连接，code:%ld,reason:%@,wasClean:%d",code,reason,wasClean);
    
    [self destoryHeartBeat]; //断开连接时销毁心跳
    
    //判断网络环境
    if (AFNetworkReachabilityManager.sharedManager.networkReachabilityStatus == AFNetworkReachabilityStatusNotReachable){ //没有网络
        [self noNetWorkStartTestingTimer];//开启网络检测
    }else{ //有网络
//        DLog(@"关闭连接");
        _webSocket = nil;
        [self reConnectServer];//连接失败就重连
    }
}

///ping
-(void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongData{
    NSDictionary * dicJson = [NSJSONSerialization JSONObjectWithData:pongData options:NSJSONReadingMutableContainers error:nil];
    NSLog(@"接受pong数据--> %@",dicJson);
//    DLog(@"接受pong数据--> %@",dicJson);
}


#pragma mark - NSTimer

//初始化心跳
- (void)initHeartBeat{
    //心跳没有被关闭
    if(self.heartBeatTimer) {
        return;
    }
    [self destoryHeartBeat];
    dispatch_main_async_safe(^{
        self.heartBeatTimer  = [NSTimer timerWithTimeInterval:15 target:self selector:@selector(senderheartBeat) userInfo:nil repeats:true];
        [[NSRunLoop currentRunLoop]addTimer:self.heartBeatTimer forMode:NSRunLoopCommonModes];
    });
}
//重新连接
- (void)reConnectServer{
    if(self.webSocket.readyState == SR_OPEN){
        return;
    }
    
    if(self.reConnectTime > 1024){  //重连10次 2^10 = 1024
        self.reConnectTime = 0;
        return;
    }
    
    __weak typeof(self)weakself = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.reConnectTime *NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

        if(weakself.webSocket.readyState == SR_OPEN && weakself.webSocket.readyState == SR_CONNECTING) {
            return;
        }

        [weakself connectServer];
        //        CTHLog(@"正在重连......");

        if(weakself.reConnectTime == 0){  //重连时间2的指数级增长
            weakself.reConnectTime = 2;
        }else{
            weakself.reConnectTime *= 2;
        }
    });
    
}

//发送心跳
- (void)senderheartBeat{

    //和服务端约定好发送什么作为心跳标识，尽可能的减小心跳包大小
    __weak typeof(self)weakself = self;
    dispatch_main_async_safe(^{
        if(weakself.webSocket.readyState == SR_OPEN){
            [weakself sendPing:nil];
        }
    });
}

//没有网络的时候开始定时 -- 用于网络检测
- (void)noNetWorkStartTestingTimer{
    __weak typeof(self)weakself = self;
    dispatch_main_async_safe(^{
        weakself.netWorkTestingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:weakself selector:@selector(noNetWorkStartTesting) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:weakself.netWorkTestingTimer forMode:NSDefaultRunLoopMode];
    });
}
//定时检测网络
- (void)noNetWorkStartTesting{
    //有网络
    if(AFNetworkReachabilityManager.sharedManager.networkReachabilityStatus != AFNetworkReachabilityStatusNotReachable)
    {
        //关闭网络检测定时器
        [self destoryNetWorkStartTesting];
        //开始重连
        [self reConnectServer];
    }
}

//取消网络检测
- (void)destoryNetWorkStartTesting{
  
    __weak typeof(self)weakself = self;
    dispatch_main_async_safe(^{
        if(weakself.netWorkTestingTimer)
        {
            [weakself.netWorkTestingTimer invalidate];
            weakself.netWorkTestingTimer = nil;
        }
    });
}


//取消心跳
- (void)destoryHeartBeat{
    __weak typeof(self)weakself = self;

    dispatch_main_async_safe(^{
        if(weakself.heartBeatTimer)
        {
            [weakself.heartBeatTimer invalidate];
            weakself.heartBeatTimer = nil;
        }
    });
}


//关闭长连接
- (void)RMWebSocketClose{
    self.isActivelyClose = YES;
    self.isConnect = NO;
    self.connectType = YYWebSocketDefault;
    if(self.webSocket)
    {
        [self.webSocket close];
        _webSocket = nil;
    }
    
    //关闭心跳定时器
    [self destoryHeartBeat];
    
    //关闭网络检测定时器
    [self destoryNetWorkStartTesting];
}


//发送数据给服务器
- (void)sendDataToServer:(NSArray *)data{
    [self.sendDataArray addObject:data];
    //[_webSocket sendString:data error:NULL];
    
    //没有网络
    if (AFNetworkReachabilityManager.sharedManager.networkReachabilityStatus == AFNetworkReachabilityStatusNotReachable)
    {
        //开启网络检测定时器
        [self noNetWorkStartTestingTimer];
    }
    else //有网络
    {
        if(self.webSocket != nil)
        {
            // 只有长连接OPEN开启状态才能调 send 方法，不然会Crash
            if(self.webSocket.readyState == SR_OPEN)
            {
                [_webSocket send:data]; //发送数据
            }
            else if (self.webSocket.readyState == SR_CONNECTING) //正在连接
            {
//                DLog(@"正在连接中，重连后会去自动同步数据");
            }
            else if (self.webSocket.readyState == SR_CLOSING || self.webSocket.readyState == SR_CLOSED) //断开连接
            {
                //调用 reConnectServer 方法重连,连接成功后 继续发送数据
                [self reConnectServer];
            }
        }
        else
        {
            [self connectServer]; //连接服务器
        }
    }
}

@end
