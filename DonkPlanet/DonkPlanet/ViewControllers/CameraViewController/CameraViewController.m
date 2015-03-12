//
//  CameraViewController.m
//  DonkPlanet
//
//  Created by Varun on 20/01/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "CameraViewController.h"
#import "CaptureViewController.h"

#import "AVCamCaptureManager.h"
#import "AVCamRecorder.h"

@interface CameraViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVCamCaptureManagerDelegate, UIGestureRecognizerDelegate> {
    
    __weak IBOutlet UIImageView *imgPhoto;
    __weak IBOutlet UIButton *btnPhotoVideoToggle;
    __weak IBOutlet UIButton *btnCapture;
    __weak IBOutlet UIButton *btnLibrary;
    __weak IBOutlet UIView *viewVideoPreview;
    __weak IBOutlet UIProgressView *progressVideo;
    
    __weak IBOutlet UIBarButtonItem *brBtnCross;
    __weak IBOutlet UIButton *btnFlip;
    __weak IBOutlet UIBarButtonItem *btnFlash;
    
    AVCamCaptureManager *captureManager;
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
    
    BOOL flashOn, movieCapture;
    UIView *viewLoading;
    
    NSTimer *timerVideo;
}

@end

@implementation CameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [self.navigationController.navigationBar setBarTintColor:[UIColor blackColor]];
    [self setupCaptureManager];
    [self setupCameraView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [progressVideo setProgress:0.0f animated:NO];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Setup Capture Manager

- (void)setupCaptureManager {
    
    if (captureManager == nil) {
        AVCamCaptureManager *manager = [[AVCamCaptureManager alloc] init];
        captureManager = manager;
        
        [captureManager setDelegate:self];
        
        if ([captureManager setupSession]) {
            // Create video preview layer and add it to the UI
            AVCaptureVideoPreviewLayer *newCaptureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:[captureManager session]];
            UIView *view = viewVideoPreview;
            CALayer *viewLayer = [view layer];
            [viewLayer setMasksToBounds:YES];
            
            CGRect bounds = [view bounds];
            [newCaptureVideoPreviewLayer setFrame:bounds];
            [newCaptureVideoPreviewLayer layoutIfNeeded];
            [newCaptureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
            
            [viewLayer insertSublayer:newCaptureVideoPreviewLayer below:[viewLayer sublayers][0]];
            captureVideoPreviewLayer = newCaptureVideoPreviewLayer;

            // Start the session. This is done asychronously since -startRunning doesn't return until the session is running.
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [[captureManager session] startRunning];
            });
            
//            [self updateButtonStates];
            
            // Add a single tap gesture to focus on the point tapped, then lock focus
            UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToAutoFocus:)];
            [singleTap setDelegate:self];
            [singleTap setNumberOfTapsRequired:1];
            [view addGestureRecognizer:singleTap];
            
            // Add a double tap gesture to reset the focus mode to continuous auto focus
            UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToContinouslyAutoFocus:)];
            [doubleTap setDelegate:self];
            [doubleTap setNumberOfTapsRequired:2];
            [singleTap requireGestureRecognizerToFail:doubleTap];
            [view addGestureRecognizer:doubleTap];
            
        }		
    }
}

#pragma mark - UIImagePickerController Delegates

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    [picker dismissViewControllerAnimated:YES completion:^ {
        
        [imgPhoto setImage:[info objectForKey:UIImagePickerControllerEditedImage]];
        UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:_DP_StoryboardName
                                                                 bundle:nil];
        CaptureViewController *objCaptureView = (CaptureViewController *)[mainStoryBoard instantiateViewControllerWithIdentifier:_DP_CaptureViewStrbdID];
        [objCaptureView setImageCaptured:[info objectForKey:UIImagePickerControllerEditedImage]];
        [self.navigationController pushViewController:objCaptureView animated:YES];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Setup View

- (void)setupCameraView {
    
    CGAffineTransform transform = CGAffineTransformMakeScale(1.0f, 5.0f);
    progressVideo.transform = transform;
    
    [viewVideoPreview.layer setShadowColor:[UIColor darkGrayColor].CGColor];
    [viewVideoPreview.layer setShadowOffset:CGSizeMake(0, 2)];
    [viewVideoPreview.layer setShadowOpacity:0.8];
    
    [btnCapture setBackgroundColor:[UIColor whiteColor]];
    [btnCapture.layer setCornerRadius:btnCapture.frame.size.width/2];
    [btnCapture setImage:[self inverseColor:[UIImage imageNamed:@"camera_icon"]]
                forState:UIControlStateNormal];
}

#pragma mark - Other Methods

- (UIImage *)inverseColor:(UIImage *)image {
    
    CIImage *coreImage = [CIImage imageWithCGImage:image.CGImage];
    CIFilter *filter = [CIFilter filterWithName:@"CIColorInvert"];
    [filter setValue:coreImage forKey:kCIInputImageKey];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    return [UIImage imageWithCIImage:result];
}

- (void)updateProgress:(NSTimer *)timer {
    
    CGFloat currentProgess = progressVideo.progress;
    
    if (currentProgess > 1.00) {
        [timer invalidate];
    }
    else {
        currentProgess += 1/300.0f;
        [progressVideo setProgress:currentProgess];
    }
}

- (void)enableNavigationItems:(BOOL)enable {
    [brBtnCross setEnabled:enable];
    [btnFlash setEnabled:enable];
    [btnFlip setEnabled:enable];
}

#pragma mark - IBAction Top View

- (IBAction)buttonCrossTouched:(id)sender {
    
    DPTabbarController *mainTabbar = (DPTabbarController *)self.tabBarController;
    
    NSInteger lastSelectedIndex = mainTabbar.lastSelectedTab;
    
    NSArray *viewControllers = [mainTabbar viewControllers];
    UIViewController *selectedViewController = [viewControllers objectAtIndex:lastSelectedIndex];
    [mainTabbar.delegate tabBarController:mainTabbar didSelectViewController:selectedViewController];
    [mainTabbar setSelectedIndex:lastSelectedIndex];
    [mainTabbar setLastSelectedTab:lastSelectedIndex];
}

- (IBAction)buttonCameraReverseTouched:(UIButton *)sender {
    [captureManager toggleCamera];
    [captureManager continuousFocusAtPoint:CGPointMake(.5f, .5f)];
}

- (IBAction)buttonFlashTouched:(UIBarButtonItem *)sender {
    
    flashOn = !flashOn;
    NSString *strImageName = flashOn ? @"flashOff" : @"flashOn";
    [sender setImage:[UIImage imageNamed:strImageName]];
}

#pragma mark - IBAction Capture View

- (IBAction)buttonVideoCameraToggleTouched:(UIButton *)sender {
    
    movieCapture = !movieCapture;
    NSString *strImageName = movieCapture ? @"camera_icon" : @"movie_icon";
    NSString *strInverseImageName = movieCapture ? @"movie_icon" : @"camera_icon";
    
    UIImage *imageSimple = [UIImage imageNamed:strImageName];
    UIImage *imageInverse = [self inverseColor:[UIImage imageNamed:strInverseImageName]];
    
    [btnCapture setImage:imageInverse forState:UIControlStateNormal];
    [btnPhotoVideoToggle setImage:imageSimple forState:UIControlStateNormal];
}

- (IBAction)buttonCaptureTouched:(id)sender {
    
//    NSString *pathForFile = [[NSBundle mainBundle] pathForResource:@"2minute" ofType:@"mov"];
//    [self generateImageForVideoAtPath:pathForFile];
    if (movieCapture) {
        
        BOOL isRecording = [[captureManager recorder] isRecording];
        
        if (!isRecording) {
            
            [self enableNavigationItems:NO];
            
            [progressVideo setProgress:0.0f animated:YES];
            timerVideo = [NSTimer scheduledTimerWithTimeInterval:0.1f
                                                          target:self
                                                        selector:@selector(updateProgress:)
                                                        userInfo:nil repeats:YES];
            [self performSelector:@selector(stopRecordingAfterHalfMinute)
                       withObject:nil
                       afterDelay:30];
            [captureManager startRecording];
        }
        else {
            [self stopRecordingAfterHalfMinute];
        }
        
        [btnPhotoVideoToggle setEnabled:isRecording];
        [btnLibrary setEnabled:isRecording];
    }
    else {
        [captureManager captureStillImage];
        
        // Flash the screen white and fade it out to give UI feedback that a still image was taken
        UIView *flashView = [[UIView alloc] initWithFrame:[viewVideoPreview frame]];
        [flashView setBackgroundColor:[UIColor whiteColor]];
        [viewVideoPreview addSubview:flashView];
        
        [UIView animateWithDuration:.4f
                         animations:^{
                             [flashView setAlpha:0.f];
                         }
                         completion:^(BOOL finished){
                             [flashView removeFromSuperview];
                         }
         ];
    }
    
}

- (IBAction)buttonPhotoLibraryTouched:(id)sender {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    else
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:^ {
        [picker.navigationBar setTintColor:[UIColor blackColor]];
    }];

}

#pragma mark - Stop Recording

- (void)stopRecordingAfterHalfMinute {

    if ([[captureManager recorder] isRecording]) {

        viewLoading = [_DPFunctions showLoadingViewWithText:@"Optimizing"
                                                     inView:viewVideoPreview];
        [self enableNavigationItems:YES];
        [progressVideo setProgress:1.0f animated:YES];
        [timerVideo invalidate];
        [captureManager stopRecording];
    }
}

#pragma mark - Methods To Focus

// Auto focus at a particular point. The focus mode will change to locked once the auto focus happens.
- (void)tapToAutoFocus:(UIGestureRecognizer *)gestureRecognizer {
    
    if ([[[captureManager videoInput] device] isFocusPointOfInterestSupported]) {
        CGPoint tapPoint = [gestureRecognizer locationInView:viewVideoPreview];
        CGPoint convertedFocusPoint = [captureVideoPreviewLayer captureDevicePointOfInterestForPoint:tapPoint];
        [captureManager autoFocusAtPoint:convertedFocusPoint];
    }
}

// Change to continuous auto focus. The camera will focus as needed at the point choosen.
- (void)tapToContinouslyAutoFocus:(UIGestureRecognizer *)gestureRecognizer
{
    if ([[[captureManager videoInput] device] isFocusPointOfInterestSupported])
        [captureManager continuousFocusAtPoint:CGPointMake(.5f, .5f)];
}

#pragma mark - Capture Manager Delegate

- (void)captureManager:(AVCamCaptureManager *)captureManager didFailWithError:(NSError *)error {
    
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                            message:[error localizedFailureReason]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"OK button title")
                                                  otherButtonTitles:nil];
        [alertView show];
    });
}

- (void)captureManagerRecordingBegan:(AVCamCaptureManager *)captureManager {
    
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
//        [[self recordButton] setTitle:NSLocalizedString(@"Stop", @"Toggle recording button stop title")];
//        [[self recordButton] setEnabled:YES];
    });
}

- (void)captureManagerRecordingFinished:(AVCamCaptureManager *)captureMngr withVideoURL:(NSURL *)urlVideo {
    
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
//        [[self recordButton] setTitle:NSLocalizedString(@"Record", @"Toggle recording button record title")];
//        [[self recordButton] setEnabled:YES];
        
        [self enableNavigationItems:YES];
        [timerVideo invalidate];
        [progressVideo setProgress:1.0f animated:YES];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self
                                                 selector:@selector(stopRecordingAfterHalfMinute)
                                                   object:nil];
        
        [_DPFunctions hideLoadingView:viewLoading];
        
        UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:_DP_StoryboardName
                                                                 bundle:nil];
        CaptureViewController *objCaptureView = (CaptureViewController *)[mainStoryBoard instantiateViewControllerWithIdentifier:_DP_CaptureViewStrbdID];
        [objCaptureView setImageCaptured:nil];
        [objCaptureView setUrlVideo:urlVideo];
        [self.navigationController pushViewController:objCaptureView animated:YES];
    });
}

- (void)captureManagerStillImageCaptured:(AVCamCaptureManager *)captureMngr {
    
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
//        [[self stillButton] setEnabled:YES];
        [[[UIAlertView alloc] initWithTitle:@"Image"
                                   message:@"Image Captured easily"
                                  delegate:nil
                         cancelButtonTitle:@"OK"
                          otherButtonTitles:nil, nil] show];

        UIImage *imageResized = [_DPFunctions resizeImageWithImage:captureMngr.imageCapturedFromSession
                                                            toSize:CGSizeMake(640, 640)];
        
        UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:_DP_StoryboardName
                                                                 bundle:nil];
        CaptureViewController *objCaptureView = (CaptureViewController *)[mainStoryBoard instantiateViewControllerWithIdentifier:_DP_CaptureViewStrbdID];
        [objCaptureView setImageCaptured:imageResized];
        [self.navigationController pushViewController:objCaptureView animated:YES];
        
    });
}

- (void)captureManagerDeviceConfigurationChanged:(AVCamCaptureManager *)captureManager {

//    [self updateButtonStates];
}

@end
