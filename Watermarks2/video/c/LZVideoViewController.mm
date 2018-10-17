//
//  LZVideoViewController.m
//  Watermarks
//
//  Created by people on 2018/10/9.
//  Copyright © 2018 people. All rights reserved.
//

#import "LZVideoViewController.h"
#import "ClipView.h"
#import "FramesShowViewController.h"
#import "UIImage+OpenCV.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "HJImagesToVideo.h"
#import "UIImage+Extension.h"
#import <GPUImage.h>

@interface LZVideoViewController ()
{
    AVPlayer *player;
    int second; // 获取视频总时长,单位秒
    CGRect rectInImage;
    BOOL rectDraw;
}
@property (weak, nonatomic) IBOutlet UIView *goBack;
@property (weak, nonatomic) IBOutlet UIView *goReset;

@property (weak, nonatomic) IBOutlet UIView *videoView;

@property(strong,nonatomic) ClipView *clipView;
@property(strong,nonatomic) AVPlayerViewController *playerVC;
@property(assign,nonatomic) CGPoint startPoint;
@property(assign,nonatomic) CGFloat factor_scale;
@property(assign,nonatomic) CGPoint offsetImageToImageView;
@property(strong,nonatomic) UIImage *image;
@property(strong,nonatomic) AVAssetTrack *srcAudioTrack;
@property(strong,nonatomic) NSURL *picsTovideoPath;
@property(strong,nonatomic) NSMutableArray *imageArray;
@property(strong,nonatomic) AVAsset *movieAsset;
@property(strong,nonatomic) NSMutableArray *times;
//@property(strong,nonatomic) NSMutableArray *imageArrayFinished; //处理完的图片集合
@property(strong,nonatomic) NSMutableArray *video_url_arrays;
@property(strong,nonatomic) NSMutableArray* video_photo_arrays;
@end

@implementation LZVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initBarButtonItem];
    [self initViewAction];
    [self initPlayer];
    [self initVideoPhoto];
    [self initClipView];
    [self initSplitVideoToImages];
}
//初始化 转换 把视频->图片集合
-(void)initSplitVideoToImages{
    self.video_photo_arrays=[NSMutableArray array];//视频图片的集合
    NSMutableArray* temp_image_array_finished=[NSMutableArray array];
    [self splitVideoHandle:self.videoUrl fps:10 splitCompleteBlock:^(NSInteger total_count, UIImage *splitimg) {
        [temp_image_array_finished addObject:splitimg];
        if (total_count==temp_image_array_finished.count){
            [self.video_photo_arrays addObject:temp_image_array_finished];
        }
    }];
}
//初始化播放器
-(void)initPlayer{
    //载入播放器
    self.video_url_arrays=[NSMutableArray array];
    self.picsTovideoPath=self.videoUrl;
    
    player = [AVPlayer playerWithURL:self.picsTovideoPath];
    self.playerVC = [[AVPlayerViewController alloc]init];
    self.playerVC.player = player;
    self.playerVC.view.frame = CGRectMake(0, 0, self.videoView.frame.size.width, self.videoView.frame.size.height);
    player.externalPlaybackVideoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.videoView addSubview:self.playerVC.view];
    self.playerVC.showsPlaybackControls = NO;
}
//初始化 clipView
-(void)initClipView{
    self.clipView = [[ClipView alloc] init];
    [self.videoView addSubview:self.clipView];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self.videoView addGestureRecognizer:pan];
    self.videoView.userInteractionEnabled = YES;
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
    [player play];
}
//初始化 videoPhoto
-(void)initVideoPhoto{
//    self.imageArrayFinished=[NSMutableArray array];
    FramesShowViewController *framesShowCon = [[FramesShowViewController alloc] init];
    framesShowCon.videoUrl = self.videoUrl;
    self.movieAsset = [AVAsset assetWithURL:self.videoUrl]; // fileUrl:文件路径
    second = (int)self.movieAsset.duration.value / self.movieAsset.duration.timescale; // 获取视频总时长,单位秒
    //取第1帧
    self.image = [self getVideoPreViewImage];
}
-(void)initViewAction{
    UITapGestureRecognizer *tapGestureBack = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bottomAction:)];
    //把手势添加到View上面；
    [self.goBack addGestureRecognizer:tapGestureBack];
    UITapGestureRecognizer *tapGestureRest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bottomAction:)];
    //把手势添加到View上面；
    [self.goReset addGestureRecognizer:tapGestureRest];
}

-(void)bottomAction:(UIPanGestureRecognizer*)panGesture{
    UIView * actionView=[panGesture view];
    switch (actionView.tag) {
        case 1:
            [self getBackResetVideoUrl:YES];
            break;
        case 2:
            [self getBackResetVideoUrl:NO];
            break;
        default:
            break;
    }
}
- (IBAction)itemAction:(id)sender {
    UIButton * senderBt=sender;
    switch (senderBt.tag) {
        case 1:
            //a返回
            [self.navigationController popViewControllerAnimated:true];
            break;
        case 2:
            NSLog(@"点击修改视频---->>>>");
            ///开始去水印
            if (self.clipView.frame.size.height < 2.0 && self.clipView.frame.size.width<2.0){
                [self toasWithInfo:@"请修改视频"];
            }else{
                [self on_click_handle];
            }
            break;
        case 3:
            ///
            NSLog(@"点击保存视频---->>>>");
            if(self.video_url_arrays.count == 0){
                [self toasWithInfo:@"请修改视频"];
            }else{
                [self save_video_to_library:self.video_url_arrays.lastObject];
            }
            break;
        default:
            break;
    }
}
-(void)getBackResetVideoUrl:(BOOL)flag{
    if (flag) {//返回上一级
        if (self.video_url_arrays.count>0) {
            [self.video_url_arrays removeLastObject];
            NSLog(@"当前的集合长度%@",self.video_url_arrays);
            if(self.video_url_arrays.count==0){
                self.picsTovideoPath=self.videoUrl; //重置视频地址
            }else{
                self.picsTovideoPath=[self.video_url_arrays lastObject];//重置视频地址
            }
            player = [AVPlayer playerWithURL:self.picsTovideoPath];
            self.playerVC.player = player;
            [self.playerVC.player play];
            if(self.video_photo_arrays.count>0){
                [self.video_photo_arrays removeLastObject];
            }
            
        }else{
            [self toasWithInfo:@"请修改视频"];
        }
    }else{//重置清空集合
        if (self.video_url_arrays.count>0) {
            [self.video_url_arrays removeAllObjects];
            self.picsTovideoPath=self.videoUrl; //重置视频地址
            player = [AVPlayer playerWithURL:self.picsTovideoPath];
            self.playerVC.player = player;
            [self.playerVC.player play];
            if(self.video_photo_arrays.count>0){
                NSMutableArray* temp_arr=[self.video_photo_arrays objectAtIndex:0];
                [self.video_photo_arrays removeAllObjects];
                [self.video_photo_arrays addObject:temp_arr];
            }
        }else{
            [self toasWithInfo:@"请修改视频"];
        }
    }
}
///初始化顶部的item
-(void)initBarButtonItem{
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRGBRed:145.0 green:190.0 blue:231.0];
    UIBarButtonItem * handleButton=[[UIBarButtonItem alloc] initWithTitle:@"去水印" style:UIBarButtonItemStylePlain target:self action:@selector(itemAction:)];
    handleButton.tintColor=[UIColor whiteColor ];
    handleButton.tag=2;
    
    UIBarButtonItem * saveButton=[[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStylePlain target:self action:@selector(itemAction:)];
    saveButton.tintColor=[UIColor whiteColor ];
    saveButton.tag=3;
    
    self.navigationItem.rightBarButtonItems = @[saveButton,handleButton];

    UIBarButtonItem* backItem=[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"返回"] style:UIBarButtonItemStylePlain target:self action:@selector(itemAction:)];
    backItem.tintColor=[UIColor whiteColor ];
    backItem.tag=1;
    self.navigationItem.leftBarButtonItem=backItem;
}
#pragma 内部处理的函数
-(void)on_click_handle{
    if (rectDraw) {
        [self toast_loading];
        dispatch_queue_t serial_queue= dispatch_queue_create("com.lz.location", NULL);
        dispatch_async(serial_queue, ^{
            NSMutableArray * temp_handle_mutil_images=[NSMutableArray array];
            NSMutableArray * temp_handle_images_arr=[self.video_photo_arrays lastObject];
            
            [self on_click_handle_mutil:temp_handle_images_arr market_image_block:^(UIImage *handle_image) {
                [temp_handle_mutil_images addObject:handle_image];
                if (temp_handle_mutil_images.count==temp_handle_images_arr.count) {
                    [temp_handle_mutil_images sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                        //此处的规则含义为：若前一元素比后一元素大，则返回升序 （即后一元素在前，为从小到大排列）
                        if ([[obj1 nameWithSetterGetter] intValue] > [[obj2 nameWithSetterGetter] intValue])
                        {
                            return NSOrderedDescending;
                        }
                        else
                        {
                            return NSOrderedAscending;
                        }
                    }];
                    [self.video_photo_arrays addObject:temp_handle_mutil_images];
                    [self imagesToVideo:temp_handle_mutil_images];
                }
            }];
        });
       
    }
}
//保存的时候 图片修复 开启多线程
-(void)on_click_handle_mutil:(NSMutableArray*)temp_images_arr market_image_block:(void(^)(UIImage* handle_image)) market_image_block{
    int split_count=10;
    int count_times=temp_images_arr.count/split_count;//分割的数量
    CGRect waterMarkRect = rectInImage;
    dispatch_queue_t queue = dispatch_queue_create("net.bujige.testQueue", DISPATCH_QUEUE_CONCURRENT);
    for (int i=0; i<count_times; i++) {
        dispatch_async(queue, ^{
            for (int j=0; j<split_count; j++) {
                UIImage * temp_uiimage=[temp_images_arr objectAtIndex:i*split_count+j];
                UIImage * temp_uiimage_market=[temp_uiimage WaterMarkDelete:waterMarkRect];
                [temp_uiimage_market setNameWithSetterGetter:[NSString stringWithFormat:@"%@",[temp_uiimage nameWithSetterGetter]] ];
                if (market_image_block != nil) {
                    market_image_block(temp_uiimage_market);
                }
            }
        });
    }
    //处理余数
    if((temp_images_arr.count-split_count*count_times)>0){
        dispatch_async(queue, ^{
            for (int i=split_count*count_times; i<temp_images_arr.count; i++) {
                UIImage * temp_uiimage=[temp_images_arr objectAtIndex:i];
                UIImage * temp_uiimage_market=[temp_uiimage WaterMarkDelete:waterMarkRect];
                [temp_uiimage_market setNameWithSetterGetter:[NSString stringWithFormat:@"%@",[temp_uiimage nameWithSetterGetter]] ];
                if (market_image_block != nil) {
                    market_image_block(temp_uiimage_market);
                }
            }
        });
    }
}


-(void)splitVideoHandle:(NSURL*)fileUrl fps:(float)fps splitCompleteBlock:(void(^)(NSInteger total_count,UIImage* splitimg))splitImageBolck{
    if (!fileUrl){
        return;
    }
    NSDictionary *optDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *avasset = [[AVURLAsset alloc] initWithURL:fileUrl options:optDict];

    CMTime cmtime = avasset.duration; //视频时间信息结构体
    Float64 durationSeconds = CMTimeGetSeconds(cmtime); //视频总秒数
    Float64 totalFrames = durationSeconds * fps; //获得视频总帧数
    __block int mtotalCount = 0;

    NSMutableArray *times_total = [self handleSplitTimesToImage:totalFrames fps:fps block:^(NSInteger totalCount) {
        mtotalCount=totalCount;
    }];
    dispatch_queue_t queue = dispatch_queue_create("net.bujige.testQueue", DISPATCH_QUEUE_CONCURRENT);
    for (int i=0; i<times_total.count; i++) {
        dispatch_async(queue, ^{
            // 追加任务1
            AVAssetImageGenerator *imgGenerator1 = [[AVAssetImageGenerator alloc] initWithAsset:avasset]; //防止时间出现偏差
            imgGenerator1.requestedTimeToleranceBefore = kCMTimeZero;
            imgGenerator1.requestedTimeToleranceAfter = kCMTimeZero;
            NSMutableArray* split_time_array=[times_total objectAtIndex:i];
            [imgGenerator1 generateCGImagesAsynchronouslyForTimes:split_time_array completionHandler:^(CMTime requestedTime, CGImageRef _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
                switch (result) {
                    case AVAssetImageGeneratorCancelled:
                        NSLog(@"Cancelled");
                        break;
                    case AVAssetImageGeneratorFailed:
//                        NSLog(@"Failed%@<--->以及%@--->%@",image,result);
                        break;
                    case AVAssetImageGeneratorSucceeded: {
                        UIImage *frameImg = [UIImage imageWithCGImage:image];
                        UIImage *frameFit = [self reSizeImage:frameImg toSize:CGSizeMake((int)frameImg.size.width - (int)frameImg.size.width%16, (int)frameImg.size.height - (int)frameImg.size.height%16)];
                        if (requestedTime.value==mtotalCount-1){
                            NSLog(@"分割完毕");
                        }
                        [frameFit setNameWithSetterGetter:[NSString stringWithFormat:@"%lli",requestedTime.value]];
                        if (splitImageBolck) {
                            splitImageBolck(mtotalCount,frameFit);
                        }
                    }
                        break;
                }
            }];
        });
    }
}
//通过times直接转换image
-(NSMutableArray*)handleSplitTimesToImage:(Float64)total_times fps:(float)fps block:(void(^)(NSInteger totalCount))splitImageArrBlock{
    ///分割时间片段
    int split_count=fps;
    NSMutableArray* totalTimesArray=[NSMutableArray array];
    int count_times=total_times/split_count;//分割的数量
    CMTime timeFrame;
    for (int i=0; i<count_times; i++) {
        NSMutableArray *times_small = [NSMutableArray array];//小的分割片段
        for (int j=0; j<split_count; j++) {
            timeFrame = CMTimeMake(i*split_count+j, fps); //第i帧 帧率
            NSValue *timeValue = [NSValue valueWithCMTime:timeFrame];
            [times_small addObject:timeValue];
        }
        [totalTimesArray addObject:times_small];
    }
    //处理余数
    if((total_times-split_count*count_times)>0){
        NSMutableArray *times_small = [NSMutableArray array];//小的分割片段
        for (int i=split_count*count_times; i<total_times; i++) {
            timeFrame = CMTimeMake(i, fps); //第i帧 帧率
            NSValue *timeValue = [NSValue valueWithCMTime:timeFrame];
            [times_small addObject:timeValue];
        }
        [totalTimesArray addObject:times_small];
    }
    int arr_total_count=0;
    for (int i=0; i<totalTimesArray.count; i++) {
        NSMutableArray* tempArr = [totalTimesArray objectAtIndex:i];
        arr_total_count+=tempArr.count;
    }
    splitImageArrBlock(arr_total_count);
    return totalTimesArray;
}
-(void)imagesToVideo:(NSArray <UIImage *> *)images_array {
    NSArray *paths =NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES);
    NSString *moviePath =[[paths objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat:@"temp%lu.mp4",(self.video_url_arrays.count+1)]];
    self.picsTovideoPath = [NSURL fileURLWithPath:moviePath];
    NSFileManager* fileManager=[NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:moviePath]) {
        NSLog(@" have");
        BOOL blDele= [fileManager removeItemAtPath:moviePath error:nil];
        if (blDele) {
            NSLog(@"dele success");
        }else {
            NSLog(@"dele fail");
        }
    }
    CGFloat fps_temp=10;
    //定义视频的大小
    CGSize size =CGSizeMake(self.image.size.width,self.image.size.height);
    NSError *error =nil;
    // 转成UTF-8编码
    unlink([moviePath UTF8String]);
    NSLog(@"path->%@",moviePath);
    //     iphone提供了AVFoundation库来方便的操作多媒体设备，AVAssetWriter这个类可以方便的将图像和音频写成一个完整的视频文件
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:moviePath] fileType:AVFileTypeQuickTimeMovie error:&error];
    NSParameterAssert(videoWriter);
    if(error)
        NSLog(@"error =%@", [error localizedDescription]);
    //mov的格式设置 编码格式 宽度 高度
    NSDictionary *videoSettings =[NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecTypeH264,AVVideoCodecKey,
                                  [NSNumber numberWithInt:size.width],AVVideoWidthKey,
                                  [NSNumber numberWithInt:size.height],AVVideoHeightKey,nil];

    AVAssetWriterInput *writerInput =[AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];

    NSDictionary*sourcePixelBufferAttributesDictionary =[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32ARGB],kCVPixelBufferPixelFormatTypeKey,nil];
    //    AVAssetWriterInputPixelBufferAdaptor提供CVPixelBufferPool实例,
    //    可以使用分配像素缓冲区写入输出文件。使用提供的像素为缓冲池分配通常
    //    是更有效的比添加像素缓冲区分配使用一个单独的池
    AVAssetWriterInputPixelBufferAdaptor *adaptor =[AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    if ([videoWriter canAddInput:writerInput])
    {
        NSLog(@"videoWriter canAddInput:writerInput");
    }
    else
    {
        NSLog(@"videoWriter cannotAddInput:writerInput");
    }
    [videoWriter addInput:writerInput];

    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    //合成多张图片为一个视频文件
    int total_frame = second * fps_temp;
    int frames = (int)self.movieAsset.duration.value;
    int step = frames/total_frame;
    dispatch_queue_t dispatchQueue =dispatch_queue_create("mediaInputQueue",NULL);
    int __block frame =0;
//    NSLog(@"数据长度%i",[images_array count] * step);
    [writerInput requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:^{
        while([writerInput isReadyForMoreMediaData])
        {
            if(++frame >=[images_array count] * 1)
            {
                [writerInput markAsFinished];
                [videoWriter finishWritingWithCompletionHandler:^(){
                    NSLog (@"finished writing");
                    dispatch_sync(dispatch_queue_create("www.lz.com", NULL), ^{
                        [self addAudioToVideo:self.srcAudioTrack videoURL:self.videoUrl];
                    });
                }];
                break;
            }
            CVPixelBufferRef buffer =NULL;
            int idx =frame / 1;
            NSLog(@"idx==%d",idx);
            buffer = (CVPixelBufferRef)[self pixelBufferFromCGImage:[[images_array objectAtIndex:idx] CGImage] size:size];
            if (buffer)
            {
                if(![adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(frame,fps_temp)])//设置每秒钟播放图片的个数
                {
                    NSLog(@"FAIL");
                }
                else
                {
                    NSLog(@"OK");
                }
                CFRelease(buffer);
            }
        }
    }];
}
//获取第一帧图片
- (UIImage*) getVideoPreViewImage
{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:self.videoUrl options:nil];
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    gen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *img = [[UIImage alloc] initWithCGImage:image];
    UIImage *imgFit = [self reSizeImage:img toSize:CGSizeMake((int)img.size.width - (int)img.size.width%16, (int)img.size.height - (int)img.size.height%16)];
    CGImageRelease(image);
    return imgFit;
}
//处理手势
-(void)pan:(UIPanGestureRecognizer*)panner{
    CGPoint endPoint = CGPointZero;
    if (panner.state == UIGestureRecognizerStateBegan) {
        self.startPoint = [self pickerPointJudge:self.videoView pointInView:[panner locationInView:self.videoView]];
    }
    else if (panner.state == UIGestureRecognizerStateChanged){
        endPoint = [self pickerPointJudge:self.videoView pointInView:[panner locationInView:self.videoView]];;
        CGFloat clipWidth = endPoint.x - self.startPoint.x;
        CGFloat clipHeight = endPoint.y - self.startPoint.y;
        self.clipView.frame = CGRectMake(self.startPoint.x, self.startPoint.y, clipWidth, clipHeight);
    }
    else if (panner.state == UIGestureRecognizerStateEnded){
        rectInImage = CGRectMake((self.clipView.frame.origin.x - self.offsetImageToImageView.x)/ self.factor_scale, (self.clipView.frame.origin.y - self.offsetImageToImageView.y) / self.factor_scale, self.clipView.frame.size.width/ self.factor_scale, self.clipView.frame.size.height/ self.factor_scale);
        rectDraw = YES;
    }
}
- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size
{
    NSDictionary *options =[NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithBool:YES],kCVPixelBufferCGImageCompatibilityKey,
                            [NSNumber numberWithBool:YES],kCVPixelBufferCGBitmapContextCompatibilityKey,nil];
    CVPixelBufferRef pxbuffer =NULL;
    CVReturn status =CVPixelBufferCreate(kCFAllocatorDefault,size.width,size.height,kCVPixelFormatType_32ARGB,(__bridge CFDictionaryRef) options,&pxbuffer);

    NSParameterAssert(status ==kCVReturnSuccess && pxbuffer !=NULL);

    CVPixelBufferLockBaseAddress(pxbuffer,0);

    void *pxdata =CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata !=NULL);
    CGColorSpaceRef rgbColorSpace=CGColorSpaceCreateDeviceRGB();
    //    当你调用这个函数的时候，Quartz创建一个位图绘制环境，也就是位图上下文。当你向上下文中绘制信息时，Quartz把你要绘制的信息作为位图数据绘制到指定的内存块。一个新的位图上下文的像素格式由三个参数决定：每个组件的位数，颜色空间，alpha选项
    CGContextRef context =CGBitmapContextCreate(pxdata,size.width,size.height,8,4*size.width,rgbColorSpace,kCGImageAlphaPremultipliedFirst);
    NSParameterAssert(context);

    //使用CGContextDrawImage绘制图片  这里设置不正确的话 会导致视频颠倒
    //    当通过CGContextDrawImage绘制图片到一个context中时，如果传入的是UIImage的CGImageRef，因为UIKit和CG坐标系y轴相反，所以图片绘制将会上下颠倒
    CGContextDrawImage(context,CGRectMake(0,0,CGImageGetWidth(image),CGImageGetHeight(image)), image);
    // 释放色彩空间
    CGColorSpaceRelease(rgbColorSpace);
    // 释放context
    CGContextRelease(context);
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(pxbuffer,0);

    return pxbuffer;
}
- (CGPoint)pickerPointJudge:(UIView*)imageView pointInView:(CGPoint)point{
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
        if (point.y > self.videoView.bounds.origin.y + self.videoView.frame.size.height) {
            point.y = self.videoView.bounds.origin.y + self.videoView.frame.size.height;
        }
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
-(void)resetVideoUrl:(NSURL*)resetPath{
    self.picsTovideoPath=resetPath; //重置视频地址
    player = [AVPlayer playerWithURL:self.picsTovideoPath];
    self.playerVC.player = player;
    [self.video_url_arrays addObject:self.picsTovideoPath]; //添加到集合中
}
//把音频添加视频
-(void)addAudioToVideo:(AVAssetTrack*)srcAudioTrack videoURL:(NSURL*)videoURL{
    // 路径
    NSArray *paths =NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES);
    NSString *outPutFilePath =[[paths objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat:@"merge%lu.mp4",(self.video_url_arrays.count+1)]];
    NSFileManager* fileManager=[NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:outPutFilePath]) {
        NSLog(@" have");
        BOOL blDele= [fileManager removeItemAtPath:outPutFilePath error:nil];
        if (blDele) {
            NSLog(@"----->>>dele success");
        }else {
            NSLog(@"dele fail");
        }
    }
    NSLog(@"----->>>dele success2222222");
    // 添加合成路径
    NSURL *outputFileUrl = [NSURL fileURLWithPath:outPutFilePath];
    // 时间起点
    CMTime nextClistartTime = kCMTimeZero;
    // 创建可变的音视频组合
    AVMutableComposition *comosition = [AVMutableComposition composition];
    // 视频采集
    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:self.picsTovideoPath options:nil];
    // 视频时间范围
    CMTimeRange videoTimeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
    // 视频通道 枚举 kCMPersistentTrackID_Invalid = 0
    AVMutableCompositionTrack *videoTrack = [comosition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    // 视频采集通道
    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    //  把采集轨道数据加入到可变轨道之中
    [videoTrack insertTimeRange:videoTimeRange ofTrack:videoAssetTrack atTime:nextClistartTime error:nil];
    //声音采集
    // 因为视频短这里就直接用视频长度了,如果自动化需要自己写判断
    CMTimeRange audioTimeRange = videoTimeRange;
    // 音频通道
    AVMutableCompositionTrack *audioTrack = [comosition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    // 加入合成轨道之中
    AVAsset *srcAsset  = [AVAsset assetWithURL:self.videoUrl];
    NSArray *trackArray = [srcAsset tracksWithMediaType:AVMediaTypeAudio];
    [audioTrack insertTimeRange:audioTimeRange ofTrack:[trackArray objectAtIndex:0] atTime:nextClistartTime error:nil];

    // 创建一个输出
    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:comosition presetName:AVAssetExportPresetMediumQuality];
    // 输出类型
    assetExport.outputFileType = AVFileTypeQuickTimeMovie;
    // 输出地址
    assetExport.outputURL = outputFileUrl;
    // 优化
    assetExport.shouldOptimizeForNetworkUse = YES;
    // 合成完毕
    [assetExport exportAsynchronouslyWithCompletionHandler:^{
        switch ([assetExport status]) {
            case AVAssetExportSessionStatusFailed: {
                NSLog(@"合成失败：%@",[[assetExport error] description]);
            } break;
            case AVAssetExportSessionStatusCancelled: {
            } break;
            case AVAssetExportSessionStatusCompleted: {
                NSLog(@"合成成功");
                [self diss_toast_loading];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self resetVideoUrl:outputFileUrl];
                    [self.clipView removeFromSuperview];
                    self.clipView = nil;
                    [self initClipView];
                });
            } break;
            default: {
                break;
            } break;
        }
    }];
}
//销毁videoPlayer和视图
-(void)dissViewPlayer{
    player=nil;
    self.playerVC.player = player;
}

///保存视频
-(void)save_video_to_library:(NSURL*)videoURL{
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:videoURL];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            [self toasWithInfo:@"视频保存成功"];
            NSFileManager* fileManager=[NSFileManager defaultManager];
            BOOL blDele= [fileManager removeItemAtURL:videoURL error:nil];
            if (blDele) {
                NSLog(@"dele1 success");
            }else {
                NSLog(@"dele1 fail");
            }
            blDele = [fileManager removeItemAtURL:self.picsTovideoPath error:nil];
            if (blDele) {
                NSLog(@"dele2 success");
            }else {
                NSLog(@"dele2 fail");
            }
        }
        if (error) {
            [self toasWithInfo:@"视频保存失败"];
            NSFileManager* fileManager=[NSFileManager defaultManager];
            BOOL blDele= [fileManager removeItemAtURL:videoURL error:nil];
            if (blDele) {
                NSLog(@"dele1 success");
            }else {
                NSLog(@"dele1 fail");
            }
            blDele = [fileManager removeItemAtURL:self.picsTovideoPath error:nil];
            if (blDele) {
                NSLog(@"dele2 success");
            }else {
                NSLog(@"dele2 fail");
            }
        }
    }];
}
//主线程
-(void)toasWithInfo:(NSString*)errMessage{
    dispatch_queue_t queue=dispatch_get_main_queue();
    dispatch_async(queue, ^{
        [MBManager showBriefAlert:errMessage];
    });
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
//设置image 到 指定大小
- (UIImage *)reSizeImage:(UIImage *)image toSize:(CGSize)reSize
{
    UIGraphicsBeginImageContext(CGSizeMake(reSize.width, reSize.height));
    [image drawInRect:CGRectMake(0, 0, reSize.width, reSize.height)];
    UIImage *reSizeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return reSizeImage;
}

- (void)viewWillAppear:(BOOL)animated{
    self.navigationController.navigationBarHidden=NO;
}

@end
