//
//  LZPhotoViewController.h
//  Watermarks
//
//  Created by people on 2018/10/9.
//  Copyright © 2018 people. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIColor+UIcolor_RGB.h"
#import <GPUImage/GPUImage.h>
#import "ClipView.h"
#import <Photos/Photos.h>
#import "UIImage+OpenCV.h"
#import<AssetsLibrary/AssetsLibrary.h>
NS_ASSUME_NONNULL_BEGIN

@interface LZPhotoViewController : UIViewController
@property(strong,nonatomic) UIImage *image;
@property(strong,nonatomic) UIImage *imageFinished;
@end

NS_ASSUME_NONNULL_END
