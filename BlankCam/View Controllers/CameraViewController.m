//
//  ViewController.m
//  BlankCam
//
//  Created by Robert Cash on 11/1/15.
//  Copyright © 2015 Robert Cash. All rights reserved.
//

#import "CameraViewController.h"

@interface CameraViewController ()

@end

@implementation CameraViewController

#pragma mark - View Management Code

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Setup Camera
    [self setUpCamera];
    
    // Make Camera Status Label invisible
    [self.cameraModeLabel setAlpha:0.0f];
    
}

-(void)viewWillAppear:(BOOL)animated{
    // Make screen brightness 0 to make screen look off
    [UIScreen mainScreen].brightness = 0.0;
    
    // Camera stuff
    dispatch_async(self.sessionQueue, ^{
        switch (self.setupResult ){
            case BlankCamSetupResultSuccess:
            {
                [self.session startRunning];
                self.sessionRunning = self.session.isRunning;
                break;
            }
            case BlankCamSetupResultCameraNotAuthorized:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString( @"BlankCam doesn't have permission to use the camera, please change privacy settings", @"Alert message when the user has denied access to the camera" );
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    // Provide quick access to Settings.
                    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"Settings", @"Alert button to open Settings" ) style:UIAlertActionStyleDefault handler:^( UIAlertAction *action ) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                    }];
                    [alertController addAction:settingsAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                } );
                break;
            }
            case BlankCamSetupResultSessionConfigurationFailed:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString( @"Unable to capture media", @"Alert message when something goes wrong during capture session configuration" );
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                } );
                break;
            }
        }
    } );

}

- (void)viewDidDisappear:(BOOL)animated
{
    dispatch_async(self.sessionQueue, ^{
        if (self.setupResult == BlankCamSetupResultSuccess ) {
            [self.session stopRunning];
        }
    } );
    
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup Code

-(void)setUpCamera {
    
    // Create the AVCaptureSession.
    self.session = [[AVCaptureSession alloc] init];
    
    // Communicate with the session and other session objects on this queue.
    self.sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL );
    
    
    // Setup the capture session.
    dispatch_async( self.sessionQueue, ^{
        if (self.setupResult != BlankCamSetupResultSuccess ) {
            return;
        }
        
        self.backgroundRecordingID = UIBackgroundTaskInvalid;
        NSError *error = nil;
        
        AVCaptureDevice *videoDevice = [CameraViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        
        if (!videoDeviceInput) {
            NSLog( @"Could not create video device input: %@", error );
        }
        
        [self.session beginConfiguration];
        
        if ([self.session canAddInput:videoDeviceInput]) {
            [self.session addInput:videoDeviceInput];
            self.videoDeviceInput = videoDeviceInput;
            
            // Tap Recognizer for photo taking
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(takePhoto)];
            [self.view addGestureRecognizer:tap];
            
            // Left Swipe Recognizer for camera switching
            UISwipeGestureRecognizer *switchSwipeLeft = [[UISwipeGestureRecognizer alloc]
                                               initWithTarget:self
                                               action:@selector(switchCamera)];
            [switchSwipeLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
            [self.view addGestureRecognizer:switchSwipeLeft];
            
            // Right Swipe Recognizer for camera switching
            UISwipeGestureRecognizer *switchSwipeRight = [[UISwipeGestureRecognizer alloc]
                                                         initWithTarget:self
                                                         action:@selector(switchCamera)];
            [switchSwipeRight setDirection:UISwipeGestureRecognizerDirectionRight];
            [self.view addGestureRecognizer:switchSwipeRight];
            
            // Swipe Recognizer for photo viewing
            UISwipeGestureRecognizer *viewSwipe = [[UISwipeGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(viewPhotoLibrary)];
            [viewSwipe setDirection:UISwipeGestureRecognizerDirectionUp];
            [self.view addGestureRecognizer:viewSwipe];
        }
        else {
            NSLog( @"Could not add video device input to the session" );
            self.setupResult = BlankCamSetupResultSessionConfigurationFailed;
        }
        
        AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        if ([self.session canAddOutput:stillImageOutput]) {
            stillImageOutput.outputSettings = @{AVVideoCodecKey : AVVideoCodecJPEG};
            [self.session addOutput:stillImageOutput];
            self.stillImageOutput = stillImageOutput;
        }
        else{
            NSLog( @"Could not add still image output to the session" );
            self.setupResult = BlankCamSetupResultSessionConfigurationFailed;
        }
        
        [self.session commitConfiguration];
    } );


}

#pragma mark - Action Code

-(void)takePhoto {
    dispatch_async( self.sessionQueue, ^{
        AVCaptureConnection *connection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        
        // Blank file plays to hide camera sound
        static SystemSoundID soundID = 0;
        if (soundID == 0) {
            NSString *path = [[NSBundle mainBundle] pathForResource:@"photoShutter2" ofType:@"caf"];
            NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];
            AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &soundID);
        }
        AudioServicesPlaySystemSound(soundID);
        
        // Capture a still image.
        [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^( CMSampleBufferRef imageDataSampleBuffer, NSError *error ) {
            if (imageDataSampleBuffer) {
                // Create image data before saving the still image to the photo library asynchronously.
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status ) {
                    if (status == PHAuthorizationStatusAuthorized) {
                        // Create an asset
                        if ([PHAssetCreationRequest class]) {
                            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                                [[PHAssetCreationRequest creationRequestForAsset] addResourceWithType:PHAssetResourceTypePhoto data:imageData options:nil];
                            } completionHandler:^( BOOL success, NSError *error ) {
                                if (!success) {
                                    NSLog( @"Error occurred while saving image to photo library: %@", error );
                                }
                            }];
                        }
                        else {
                            NSString *temporaryFileName = [NSProcessInfo processInfo].globallyUniqueString;
                            NSString *temporaryFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[temporaryFileName stringByAppendingPathExtension:@"jpg"]];
                            NSURL *temporaryFileURL = [NSURL fileURLWithPath:temporaryFilePath];
                            
                            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                                NSError *error = nil;
                                [imageData writeToURL:temporaryFileURL options:NSDataWritingAtomic error:&error];
                                if (error) {
                                    NSLog( @"Error occured while writing image data to a temporary file: %@", error );
                                }
                                else{
                                    [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:temporaryFileURL];
                                }
                            } completionHandler:^(BOOL success, NSError *error) {
                                if (!success) {
                                    NSLog( @"Error occurred while saving image to photo library: %@", error );
                                }
                                
                                // Delete the temporary file.
                                [[NSFileManager defaultManager] removeItemAtURL:temporaryFileURL error:nil];
                            }];
                        }
                    }
                }];
            }
            else {
                NSLog( @"Could not capture still image: %@", error );
            }
        }];
    } );

}

-(void)switchCamera {
    // Switches between selfie and forward facing.
    dispatch_async(self.sessionQueue, ^{
        AVCaptureDevice *currentVideoDevice = self.videoDeviceInput.device;
        AVCaptureDevicePosition preferredPosition = AVCaptureDevicePositionUnspecified;
        AVCaptureDevicePosition currentPosition = currentVideoDevice.position;
        
        switch (currentPosition){
            case AVCaptureDevicePositionUnspecified:
            case AVCaptureDevicePositionFront:
                preferredPosition = AVCaptureDevicePositionBack;
                break;
            case AVCaptureDevicePositionBack:
                preferredPosition = AVCaptureDevicePositionFront;
                break;
        }
        
        AVCaptureDevice *videoDevice = [CameraViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
        
        [self.session beginConfiguration];

        [self.session removeInput:self.videoDeviceInput];
        
        if ([self.session canAddInput:videoDeviceInput]){
            [self.session addInput:videoDeviceInput];
            self.videoDeviceInput = videoDeviceInput;
        }
        else {
            [self.session addInput:self.videoDeviceInput];
        }
        
        [self.session commitConfiguration];
        
        dispatch_async( dispatch_get_main_queue(), ^{
            switch (preferredPosition){
                case AVCaptureDevicePositionUnspecified:
                case AVCaptureDevicePositionFront:
                    self.cameraModeLabel.text = @"Selfie Mode";
                    break;
                case AVCaptureDevicePositionBack:
                    self.cameraModeLabel.text = @"Normal Mode";
                    break;
            }
            [UIView animateWithDuration:0.25f animations:^{
                [self.cameraModeLabel setAlpha:1.0f];
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.25f animations:^{
                    [self.cameraModeLabel setAlpha:0.0f];
                } completion:^(BOOL finished) {
                }];
            }];
        });
        
    } );
}

-(void)viewPhotoLibrary {
    // Get last photo taken and set up to display in new controller.
    self.lastPhotoTaken = nil;
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                                 usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                     if (nil != group) {
                                         
                                         [group setAssetsFilter:[ALAssetsFilter allPhotos]];
                                         
                                         if (group.numberOfAssets > 0) {
                                             [group enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:group.numberOfAssets - 1]
                                                                     options:0
                                                                  usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                                                                      if (nil != result) {
                                                                          ALAssetRepresentation *repr = [result defaultRepresentation];
                                                                          
                                                                        // Most recent image
                                                                        self.lastPhotoTaken = [UIImage imageWithCGImage:[repr fullScreenImage]];

                                                                        *stop = YES;
                                                                          [self performSegueWithIdentifier:@"toPreview" sender:self];
                                                                      }
                                                                  }];
                                         }
                                     }
                                     
                                     *stop = NO;
                                 } failureBlock:^(NSError *error) {
                                     NSLog(@"error: %@", error);
                                 }];

}

#pragma mark - Class Methods

+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = devices.firstObject;
    
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            captureDevice = device;
            break;
        }
    }
    
    return captureDevice;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"toPreview"]){
        LastPhotoViewController * controller = (LastPhotoViewController *) segue.destinationViewController;
        controller.lastPhotoTaken = self.lastPhotoTaken;
    }
}



@end
