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

@interface CameraViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    
    __weak IBOutlet UIBarButtonItem *btnFlash;
    __weak IBOutlet UIImageView *imgPhoto;
    __weak IBOutlet UIButton *btnPhotoVideoToggle;
    __weak IBOutlet UIButton *btnCapture;
    
    BOOL flashOn, movieCapture;
    UIView *viewLoading;
}

@end

@implementation CameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [self.navigationController.navigationBar setBarTintColor:[UIColor blackColor]];
    [self setupCameraView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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
    
    [imgPhoto.layer setShadowColor:[UIColor darkGrayColor].CGColor];
    [imgPhoto.layer setShadowOffset:CGSizeMake(0, 2)];
    [imgPhoto.layer setShadowOpacity:0.8];
    
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
}

- (IBAction)buttonFlashTouched:(UIBarButtonItem *)sender {
    
    flashOn = !flashOn;
    NSString *strImageName = flashOn ? @"flashOff" : @"flashOn";
    [sender setImage:[UIImage imageNamed:strImageName]];
}

#pragma mark - Generating Image

-(void)generateImageForVideoAtPath:(NSString *)videoPath {
    
    NSURL *url = [NSURL fileURLWithPath:videoPath];
    AVURLAsset *asset=[[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform=TRUE;
    
    CMTime thumbTime = CMTimeMakeWithSeconds(1,30);
    
    AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        if (result != AVAssetImageGeneratorSucceeded) {
            NSLog(@"couldn't generate thumbnail, error:%@", error);
        }
        // TODO Do something with the image
        dispatch_async(dispatch_get_main_queue(), ^ {
            [imgPhoto setImage:[UIImage imageWithCGImage:im]];
        });
    };
    
//    CGSize maxSize = CGSizeMake(400, 400);
//    generator.maximumSize = maxSize;
    [generator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:thumbTime]] completionHandler:handler];
    
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
    
    
    PFUser *currentUser = [PFUser currentUser];
    
    if (currentUser) {
        
        viewLoading = [_DPFunctions showLoadingViewWithText:@"Posting..." inView:self.view];
        
        NSString *userID = currentUser.objectId;
        NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
        NSString *imageFileName = [NSString stringWithFormat:@"%@-%f.mov", userID, timeInterval];
        
        NSString *pathForFile = [[NSBundle mainBundle] pathForResource:@"2minute" ofType:@"mov"];
        NSData *movieData = [NSData dataWithContentsOfFile:pathForFile];
        PFFile *movieFile = [PFFile fileWithName:imageFileName data:movieData];
        [movieFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            
            PFObject *userPhoto = [PFObject objectWithClassName:@"Post"];
            userPhoto[@"fileDesc"] = @"First Movie";
            userPhoto[@"filePosted"] = movieFile;
            userPhoto[@"fileUsername"] = currentUser.username;
            userPhoto[@"fileUserID"] = currentUser.objectId;
            userPhoto[@"fileUserEmail"] = currentUser.email;
            userPhoto[@"userPointer"] = currentUser;
            userPhoto[@"fileType"] = [NSNumber numberWithInt:PostTypeVideo];
            //            [userPhoto setObject:currentUser forKey:@"fileUser"];
            [userPhoto saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                
                [_DPFunctions hideLoadingView:viewLoading];
                
                NSString *strTitle = @"";
                NSString *strMessage = @"";
                if (!error) {
                    strTitle = @"Posted";
                    strMessage = @"The movie posted successfully on server";
                }
                else {
                    strTitle = @"Error";
                    strMessage = @"The movie can't be posted on server right now";
                }
                
                NSString *otherTitle = (!error) ? nil : @"Retry";
                NSString *cancelTitle = (!error) ? @"OK" : @"Cancel";
                
                [[[UIAlertView alloc] initWithTitle:strTitle
                                            message:strMessage
                                           delegate:self
                                  cancelButtonTitle:cancelTitle
                                  otherButtonTitles:otherTitle, nil] show];
            }];
        }];
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

@end
