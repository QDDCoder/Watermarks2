//
//  AlterTools.m
//  Watermarks
//
//  Created by people on 2018/10/17.
//  Copyright © 2018 people. All rights reserved.
//

#import "AlterTools.h"

@implementation AlterTools
+(UIAlertController*)show_msg_with:(NSString*)message sure_block:(void (^)(void))sure_block with_cancle:(void (^)(void))with_cancle{
    UIAlertController* alter_vc=[UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* alter_sure=[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        sure_block();
    }];
    UIAlertAction* alter_cancle=[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        with_cancle();
    }];
    [alter_vc addAction:alter_sure];
    [alter_vc addAction:alter_cancle];
    return alter_vc;
}
@end
