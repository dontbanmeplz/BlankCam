//
//  ViewController.h
//  BlankCam
//
//  Created by Robert Cash on 11/1/15.
//  Copyright © 2015 Robert Cash. All rights reserved.
//

@import UIKit;
@import AVFoundation;
@import AudioToolbox;
@import AssetsLibrary;
@import Photos;
#import "LastPhotoViewController.h"

static void * CapturingStillImageContext = &CapturingStillImageContext;
static void * SessionRunningContext = &SessionRunningContext;

@interface CameraViewController : UIViewController <UIImagePickerControllerDelegate>

typedef NS_ENUM( NSInteger, BlankCamSetupResult ) {
    BlankCamSetupResultSuccess,
    BlankCamSetupResultCameraNotAuthorized,
    BlankCamSetupResultSessionConfigurationFailed
};

// Session management.
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic,retain) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic) BlankCamSetupResult setupResult;
@property (nonatomic, getter=isSessionRunning) BOOL sessionRunning;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;

// Other variables
@property UIImage *lastPhotoTaken;

@end

