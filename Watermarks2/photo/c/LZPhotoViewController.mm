//
//  LZPhotoViewController.m
//  Watermarks
//
//  Created by people on 2018/10/9.
//  Copyright © 2018 people. All rights reserved.
//

#import "LZPhotoViewController.h"
#import "MBManager.h"
@interface LZPhotoViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *handleImageView;

@property (weak, nonatomic) IBOutlet UIView *goBack;
@property (weak, nonatomic) IBOutlet UIView *goReset;
@property(assign,nonatomic) CGPoint startPoint;
@property(strong,nonatomic) ClipView *clipView;
@property(assign,nonatomic) CGFloat factor_scale;
@property(assign,nonatomic) CGFloat buttomActionHeight;
@property(strong,nonatomic) NSMutableArray* imageArr;
@property(assign,nonatomic) CGPoint offsetImageToImageView;
@end

@implementation LZPhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initBarButtonItem];
    [self initViewAction];
    [self initViewAndData];
}
- (void)injected
{
    NSLog(@"I've been injected: %@", self);
    self.view.backgroundColor=[UIColor yellowColor];
}
///初始化 ui和数据
-(void)initViewAndData{
    _imageArr=[NSMutableArray arrayWithCapacity:8];
    self.handleImageView.image=self.image;
    [self initViewAndGesture];
}
///初始化 ui和手势
-(void)initViewAndGesture{
    self.clipView = [[ClipView alloc] init];
    [self.handleImageView addSubview:self.clipView];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self.handleImageView addGestureRecognizer:pan];
    self.handleImageView.userInteractionEnabled = YES;
}

///底部的view添加点击事件
-(void)initViewAction{
   UITapGestureRecognizer *tapGestureBack = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bottomAction:)];
    //把手势添加到View上面；
    [self.goBack addGestureRecognizer:tapGestureBack];
    
    UITapGestureRecognizer *tapGestureRest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bottomAction:)];
    //把手势添加到View上面；
    [self.goReset addGestureRecognizer:tapGestureRest];
}
///底部事件处理
-(void)bottomAction:(UIPanGestureRecognizer*)panGesture{
    UIView * actionView=[panGesture view];
    switch (actionView.tag) {
        case 1:
            [self forwardImage];
            break;
        case 2:
            [self resetImage];
            break;
        default:
            break;
    }
}
//画笔往前跳转
-(void)forwardImage{
    if(_imageArr.count>0){
        [_imageArr removeLastObject];
        if (_imageArr.count==0||self.handleImageView.image==nil){
            self.handleImageView.image=self.image;
        }else{
            [self setCurrentImage];
        }
    }else{
        [MBManager showBriefAlert:@"请修改图片"];
    }
}
///重置
-(void)resetImage{
    if (_imageArr.count>0){
        [_imageArr removeAllObjects];
        self.handleImageView.image=self.image;
    }else{
        [MBManager showBriefAlert:@"请修改图片"];
    }
    
}
-(void)setCurrentImage{
    [self.handleImageView setImage:_imageArr.lastObject];
}

///手势处理
-(void)pan:(UIPanGestureRecognizer*)panner{
    CGPoint endPoint = CGPointZero;
    
    if (panner.state == UIGestureRecognizerStateBegan) {
        self.startPoint = [self pickerPointJudge:self.handleImageView pointInView:[panner locationInView:self.handleImageView]];
    }
    else if (panner.state == UIGestureRecognizerStateChanged){
        endPoint = [self pickerPointJudge:self.handleImageView pointInView:[panner locationInView:self.handleImageView]];
        CGFloat clipWidth = endPoint.x - self.startPoint.x;
        CGFloat clipHeight = endPoint.y - self.startPoint.y;
        
        self.clipView.frame = CGRectMake(self.startPoint.x, self.startPoint.y, clipWidth, clipHeight);
        self.clipView.layer.cornerRadius=clipHeight*0.2;
        
    }
    else if (panner.state == UIGestureRecognizerStateEnded){
       
        
        [self toast_loading];
        dispatch_queue_t queue=dispatch_get_main_queue();
        
        [self hanle_async_image:^(UIImage *handle_image) {
            self.imageFinished=handle_image;
            [self diss_toast_loading];
            dispatch_async(queue, ^{
                [self.handleImageView setImage:self.imageFinished];
                [_imageArr addObject:self.handleImageView.image];
                [self.clipView removeFromSuperview];
                self.clipView = nil;
                [self initViewAndGesture];
            });
        }];
        
    }
}
-(void)hanle_async_image:(void(^)(UIImage* handle_image))handle_block{
    CGRect rectInImage = CGRectMake((self.clipView.frame.origin.x - self.offsetImageToImageView.x)/ self.factor_scale, (self.clipView.frame.origin.y - self.offsetImageToImageView.y) / self.factor_scale, self.clipView.frame.size.width/ self.factor_scale, self.clipView.frame.size.height/ self.factor_scale);
     dispatch_queue_t dispatch=dispatch_queue_create("www.laozhan.com", NULL);
    if (self.imageFinished==nil){
        if (handle_block != nil){
            UIImage* temp_image=self.handleImageView.image;
            dispatch_async(dispatch, ^{
                handle_block([temp_image WaterMarkDelete:rectInImage]);
            });
        }
    }else{
        if (handle_block != nil){
            UIImage* temp_image=self.handleImageView.image;
            dispatch_async(dispatch, ^{
                handle_block([temp_image WaterMarkDelete:rectInImage]);
            });
        }
    }

    
}
///顶部的item 事件处理
- (void)itemAction:(id)sender {
    UIButton * senderBt=sender;
    switch (senderBt.tag) {
        case 1:
            //a返回
            [self.navigationController popViewControllerAnimated:true];
            break;
        case 2:
            ///保存
            if(self.imageFinished == nil||_imageArr.count==0){
                [MBManager showBriefAlert:@"请修改图片"];
            }else{
                UIImageWriteToSavedPhotosAlbum(self.imageArr.lastObject, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
            }
            
        default:
            break;
    }
}
///保存图片 的错误回调
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    NSString* message=@"保存成功";
    if (error == nil) {
        message = @"保存成功";
    }else{
        message = @"保存失败";
    }
    [MBManager showBriefAlert:message];
}
///初始化顶部的item
-(void)initBarButtonItem{
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRGBRed:145.0 green:190.0 blue:231.0];
    UIBarButtonItem * saveButton=[[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStylePlain target:self action:@selector(itemAction:)];
    saveButton.tintColor=[UIColor whiteColor ];
    saveButton.tag=2;
    self.navigationItem.rightBarButtonItems = @[saveButton];
    
    UIBarButtonItem* backItem=[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"返回"] style:UIBarButtonItemStylePlain target:self action:@selector(itemAction:)];
    backItem.tintColor=[UIColor whiteColor ];
    backItem.tag=1;
    self.navigationItem.leftBarButtonItem=backItem;
}
#pragma defineBySelf
- (CGPoint)pickerPointJudge:(UIImageView*)imageView pointInView:(CGPoint)point{
    CGPoint tempPoint = CGPointMake(0, 0);
    CGFloat factor_frame = imageView.frame.size.width/imageView.frame.size.height;
    CGFloat factor_image = self.image.size.width/self.image.size.height;
    if (factor_frame < factor_image) {  //固定宽缩放
        self.factor_scale = imageView.frame.size.width/self.image.size.width;
        tempPoint.x = point.x;
        CGPoint offset = CGPointMake(0, 0.5*(imageView.frame.size.height - self.image.size.height * self.factor_scale));
        self.offsetImageToImageView = offset;
        if (point.y < 0.5*(imageView.frame.size.height - self.image.size.height * self.factor_scale)) {
            tempPoint.y = 0.5*(imageView.frame.size.height - self.image.size.height * self.factor_scale);
        }else if (point.y > 0.5*(imageView.frame.size.height + self.image.size.height * self.factor_scale)){
            tempPoint.y = 0.5*(imageView.frame.size.height + self.image.size.height * self.factor_scale);
        }
        else{
            tempPoint.y = point.y;
        }
    }else{
        self.factor_scale = imageView.frame.size.height/self.image.size.height;
        tempPoint.y = point.y;
        CGPoint offset = CGPointMake(0.5*(imageView.frame.size.width - self.image.size.width * self.factor_scale),0);
        self.offsetImageToImageView = offset;
        if (point.x < 0.5*(imageView.frame.size.width - self.image.size.width * self.factor_scale)) {
            tempPoint.x = 0.5*(imageView.frame.size.width - self.image.size.width * self.factor_scale);
        }else if (point.x > 0.5*(imageView.frame.size.width + self.image.size.width * self.factor_scale)){
            tempPoint.x = 0.5*(imageView.frame.size.width + self.image.size.width * self.factor_scale);
        }else{
            tempPoint.x = point.x;
        }
    }
    return tempPoint;
}
- (UIImage *)cropImage:(UIImage*)image toRect:(CGRect)rect {
    CGFloat (^rad)(CGFloat) = ^CGFloat(CGFloat deg) {
        return deg / 180.0f * (CGFloat) M_PI;
    };
    // determine the orientation of the image and apply a transformation to the crop rectangle to shift it to the correct position
    CGAffineTransform rectTransform;
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(90)), 0, -image.size.height);
            break;
        case UIImageOrientationRight:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(-90)), -image.size.width, 0);
            break;
        case UIImageOrientationDown:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(-180)), -image.size.width, -image.size.height);
            break;
        default:
            rectTransform = CGAffineTransformIdentity;
    };
    
    // adjust the transformation scale based on the image scale
    rectTransform = CGAffineTransformScale(rectTransform, image.scale, image.scale);
    
    // apply the transformation to the rect to create a new, shifted rect
    CGRect transformedCropSquare = CGRectApplyAffineTransform(rect, rectTransform);
    // use the rect to crop the image
    CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, transformedCropSquare);
    // create a new UIImage and set the scale and orientation appropriately
    UIImage *result = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
    // memory cleanup
    CGImageRelease(imageRef);
    
    return result;
}
- (void)viewWillAppear:(BOOL)animated{
    self.navigationController.navigationBarHidden=NO;
}
///显示加载框
-(void)toast_loading{
    dispatch_queue_t queue=dispatch_get_main_queue();
    dispatch_async(queue, ^{
        [MBManager showLoading];
    });
}
///隐藏提示框
-(void)diss_toast_loading{
    dispatch_queue_t queue=dispatch_get_main_queue();
    dispatch_async(queue, ^{
        [MBManager hideAlert];
    });
}

@end
