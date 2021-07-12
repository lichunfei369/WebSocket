//
//  ViewController.m
//  WebSocket
//
//  Created by Apple on 2021/5/12.
//

#import "ViewController.h"
#import "YYWebSocketManager.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[YYWebSocketManager shared]connectServer];
    [[YYWebSocketManager shared]sendDataToServer:@[@{@"id":@"1111"}]];
}


@end
