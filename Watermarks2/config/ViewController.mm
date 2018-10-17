//
//  ViewController.m
//  Watermarks2
//
//  Created by people on 2018/10/17.
//  Copyright © 2018 people. All rights reserved.
//

#import "ViewController.h"
#import "MBManager.h"
@interface ViewController ()
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRGBRed:145.0 green:190.0 blue:231.0];
}
- (IBAction)chose_action:(id)sender {
    UIButton* temp_button=sender;
    switch (temp_button.tag) {
        case 1:
            //选择图片
            [self onClickImageButton];
            break;
        case 2:
            //选择视频
            NSLog(@"点击了选择视频");
            [self onClickVideoButton];
            break;
        default:
            break;
    }
}
#pragma action
- (void)onClickVideoButton{
    //选择本地视频
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    ipc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;//sourcetype有三种分别是camera，photoLibrary和photoAlbum
    NSArray *availableMedia = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];//Camera所支持的Media格式都有哪些,共有两个分别是@"public.image",@"public.movie"
    ipc.mediaTypes = [NSArray arrayWithObject:availableMedia[1]];//设置媒体类型为public.movie
    [self presentViewController:ipc animated:YES completion:nil];
    ipc.delegate = self;//设置委托
}

- (void)onClickImageButton{
    UIAlertController *actionSheet = [[UIAlertController alloc] init];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"取消操作");
        //        [self showToast:@"操作已取消"];
    }];
    
    UIAlertAction *takePhoto = [UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"拍照");
        [self takePhoto];
    }];
    
    UIAlertAction *fromPictures = [UIAlertAction actionWithTitle:@"从相册中选择" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"从相册中选择图像");
        [self fromPictures];
    }];
    [actionSheet addAction:cancel];
    [actionSheet addAction:takePhoto];
    [actionSheet addAction:fromPictures];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}
#pragma imagePickerDelegate
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    NSString *mediaType=[info objectForKey:UIImagePickerControllerMediaType];
    
    if ([mediaType isEqualToString:@"public.movie"]){
        //如果是视频
        NSURL *url = info[UIImagePickerControllerMediaURL];//获得视频的URL
        NSLog(@"url %@",url);
        LZVideoViewController *videoController = [[LZVideoViewController alloc] init];
        videoController.videoUrl = url;
        [self dismissViewControllerAnimated:YES completion:nil];
        [picker dismissViewControllerAnimated:YES completion:nil];
        [self.navigationController pushViewController:videoController animated:YES];
    }else{
        [self dismissViewControllerAnimated:YES completion:nil];
        [picker dismissViewControllerAnimated:YES completion:nil];
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        LZPhotoViewController *pictureViewController = [[LZPhotoViewController alloc] init];
        pictureViewController.image = image;
        [self.navigationController pushViewController:pictureViewController animated:YES];
    }
}
#pragma defineBySelf
-(void)showToast:(NSString *)str{
    [MBManager showBriefAlert:str];
}
-(void)takePhoto{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerController.allowsEditing = NO;
    imagePickerController.delegate = self;
    
    [self presentViewController:imagePickerController animated:YES completion:nil];
}
-(void)fromPictures{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.allowsEditing = NO;
    imagePickerController.delegate = self;
    
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

@end
