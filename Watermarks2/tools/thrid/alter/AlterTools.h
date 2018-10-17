//
//  AlterTools.h
//  Watermarks
//
//  Created by people on 2018/10/17.
//  Copyright © 2018 people. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface AlterTools : NSObject
+(UIAlertController*)show_msg_with:(NSString*)message sure_block:(void (^)(void))sure_block with_cancle:(void (^)(void))with_cancle;
@end

NS_ASSUME_NONNULL_END
