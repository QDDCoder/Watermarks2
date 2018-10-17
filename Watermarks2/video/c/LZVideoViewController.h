//
//  LZVideoViewController.h
//  Watermarks
//
//  Created by people on 2018/10/9.
//  Copyright © 2018 people. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIColor+UIcolor_RGB.h"
#import <AVKit/AVKit.h>
#import <Photos/Photos.h>
#import "MBManager.h"
NS_ASSUME_NONNULL_BEGIN

@interface LZVideoViewController : UIViewController
@property(strong,nonatomic) NSURL *videoUrl;
@end

NS_ASSUME_NONNULL_END
