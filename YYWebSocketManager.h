//
//  YYWebSocketManager.h
//  CloseRange
//
//  Created by 韩亚周 on 2019/6/15.
//  Copyright © 2019 韩亚周. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRWebSocket.h"
#import "AFNetworking.h"
//#import "PPBasehelper.h"
//#import "LoginSuccessModel.h"
//#import "DBManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger,YYWebSocketConnectType){
    YYWebSocketDefault = 0,   //初始状态,未连接,不需要重新连接
    YYWebSocketConnect,       //已连接
    YYWebSocketDisconnect    //连接后断开,需要重新连接
};

@interface YYWebSocketManager : NSObject <SRWebSocketDelegate>

@property (nonatomic, strong) SRWebSocket *webSocket;
@property (nonatomic, assign) BOOL isConnect;  //是否连接
@property (nonatomic, assign) YYWebSocketConnectType connectType;

@property (nonatomic, copy) void (^webSocketManagerDidReceiveMessage) (NSString *string);

+(instancetype)shared;

//建立长连接
- (void)connectServer;
//重新连接
- (void)reConnectServer;
//关闭长连接
- (void)RMWebSocketClose;
//发送数据给服务器
- (void)sendDataToServer:(NSArray *)data;

//连接成功回调
-(void)webSocketDidOpen:(SRWebSocket *)webSocket;
//连接失败回调
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
//接收消息回调,需要提前和后台约定好消息格式.
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessageWithString:(nonnull NSString *)string;
//关闭连接回调的代理
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;

@end

NS_ASSUME_NONNULL_END
