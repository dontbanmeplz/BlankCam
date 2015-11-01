//
//  LastPhotoViewController.h
//  BlankCam
//
//  Created by Robert Cash on 11/1/15.
//  Copyright © 2015 Robert Cash. All rights reserved.
//
@import AssetsLibrary;
@import Photos;
@import UIKit;
#import "KVNProgress.h"

@interface LastPhotoViewController : UIViewController

// UI elements
@property (weak, nonatomic) IBOutlet UIImageView *lastPhotoTakenImageView;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@property KVNProgressConfiguration *configuration;

// Variables
@property UIImage *lastPhotoTaken;
@property NSURL *lastPhotoAssetUrl;

@end
