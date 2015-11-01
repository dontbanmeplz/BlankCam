//
//  LastPhotoViewController.m
//  BlankCam
//
//  Created by Robert Cash on 11/1/15.
//  Copyright © 2015 Robert Cash. All rights reserved.
//

#import "LastPhotoViewController.h"

@interface LastPhotoViewController ()

@end

@implementation LastPhotoViewController

#pragma mark - View Management Code

- (void)viewDidLoad {
    [super viewDidLoad];
    // Set up imageview and other UI related entities
    [self setUpUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup Code

-(void)setUpUI {
    // Make screen brightness at nice viewing setting
    [UIScreen mainScreen].brightness = 0.5;
    
    // Edit Delete Button
    self.deleteButton.layer.cornerRadius = 10;
    self.deleteButton.clipsToBounds = YES;
    
    // Set Photo
    self.lastPhotoTakenImageView.image = self.lastPhotoTaken;
    
    // Set up Gesture for dismiss
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc]
                                       initWithTarget:self
                                       action:@selector(dismiss)];
    [swipe setDirection:UISwipeGestureRecognizerDirectionDown];
    [self.view addGestureRecognizer:swipe];
    
    // Set up progress indicator
    self.configuration = [[KVNProgressConfiguration alloc] init];
    self.configuration.statusColor = [UIColor whiteColor];
    self.configuration.successColor = [UIColor whiteColor];
    self.configuration.errorColor = [UIColor whiteColor];
    self.configuration.circleStrokeForegroundColor = [UIColor blackColor];
    self.configuration.circleStrokeBackgroundColor = [UIColor blackColor];
    self.configuration.circleFillBackgroundColor = [UIColor blackColor];
    self.configuration.minimumSuccessDisplayTime = 4;
    self.configuration.minimumErrorDisplayTime = .75;
    self.configuration.backgroundFillColor = [UIColor whiteColor];
    self.configuration.backgroundTintColor = [UIColor whiteColor];
    [KVNProgress setConfiguration: self.configuration];
  
}

#pragma mark Action Code

- (IBAction)deletePhoto:(id)sender {
    // Get Last photo and delete it.
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:fetchOptions];
    PHAsset *lastImageAsset = [fetchResult lastObject];
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [KVNProgress dismiss];
        [KVNProgress show];
        [PHAssetChangeRequest deleteAssets:@[lastImageAsset]];
    } completionHandler:^(BOOL success, NSError *error) {
        NSLog(@"Finished deleting asset. %@", (success ? @"Success." : error));
        if(success){
            [KVNProgress dismiss];
            [self dismiss];
        }
        [KVNProgress dismiss];
    }];
}

-(void)dismiss {
    [self dismissViewControllerAnimated: YES completion: nil];
}

@end
