//
//  CaptureViewController.m
//  DonkPlanet
//
//  Created by Varun on 4/02/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "CaptureViewController.h"

@interface CaptureViewController () <UIAlertViewDelegate, UITextFieldDelegate> {
    
    __weak IBOutlet UIScrollView *scrlView;
    __weak IBOutlet UIImageView *imgCaptured;
    __weak IBOutlet UIImageView *imgCaptionBack;
    __weak IBOutlet UITextField *txtFieldCaption;
    __weak IBOutlet UIProgressView *progressUpload;
    __weak IBOutlet UIView *viewMedia;
    __weak IBOutlet UIButton *btnPlayPause;
    __weak IBOutlet UIView *viewVideo;
    __weak IBOutlet UIImageView *imgVwPlayPause;
    
    UIView *viewLoading;
    UIBarButtonItem *rightBarButtonItem;
    AVPlayer *avPlayer;
    NSDate *dateToHide;
    
    UIImage *imgVideoThumb;
    NSString *fileName;
    PFFile *fileImage;
}

@end

@implementation CaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupCaptureView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    BOOL boolImage = NO;
    if (self.imageCaptured) {
        boolImage = YES;
        [imgCaptured setImage:self.imageCaptured];
    }
    else {
        NSLog(@"Video URL : %@", self.urlVideo);
        avPlayer = [[AVPlayer alloc] initWithURL:self.urlVideo];
        
        AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:avPlayer];
        avPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        layer.frame = CGRectMake(0, 0, viewVideo.frame.size.width, viewVideo.frame.size.height);
        [viewVideo.layer addSublayer: layer];
        [avPlayer addObserver:self forKeyPath:@"rate" options:0 context:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(itemDidFinishPlaying:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:[avPlayer currentItem]];
    }
    
    [imgVwPlayPause setHidden:boolImage];
    [imgCaptured setHidden:!boolImage];
    [viewVideo setHidden:boolImage];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [avPlayer pause];
    [avPlayer removeObserver:self forKeyPath:@"rate" context:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:[avPlayer currentItem]];
    
    avPlayer = nil;
    //    for (AVPlayerLayer *avLayer in viewVideo.layer.sublayers) {
    ////        [avLayer setPlayer:nil];
    //        [avLayer removeFromSuperlayer];
    //    }
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

#pragma mark - Setup View

- (void)setupCaptureView {
    
    [self setTitle:@"Post"];
    
    UITapGestureRecognizer *tapOnScroll = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignResponders)];
    [tapOnScroll setNumberOfTapsRequired:1];
    [tapOnScroll setNumberOfTouchesRequired:1];
    [scrlView addGestureRecognizer:tapOnScroll];
    
    [scrlView setContentSize:CGSizeMake(scrlView.frame.size.width, scrlView.frame.size.height + 240)];
    [scrlView setScrollEnabled:NO];
    
    CGAffineTransform transform = CGAffineTransformMakeScale(1.0f, 5.0f);
    progressUpload.transform = transform;
    
    rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(postTheFile:)];
    [self.navigationItem setRightBarButtonItem:rightBarButtonItem animated:YES];
    
    UIImage *imageResized = [[UIImage imageNamed:@"captionback"] resizableImageWithCapInsets:UIEdgeInsetsMake(13, 13, 13, 13) resizingMode:UIImageResizingModeStretch];
    [imgCaptionBack setImage:imageResized];
}

#pragma mark - Observe key value path

- (void)itemDidFinishPlaying:(NSNotification *) notification {
    // Will be called when AVPlayer finishes playing playerItem
    
    [avPlayer setRate:0.0f];
    AVPlayerItem *playerItem = [notification object];
    [playerItem seekToTime:kCMTimeZero];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"rate"]) {
        dateToHide = [NSDate date];
        NSString *strImageName = @"";
        if ([avPlayer rate] > 0.5) {
            strImageName = @"pause";     // This changes the button to Pause
        }
        else {
            strImageName = @"play";    // This changes the button to Play
            [imgVwPlayPause setHidden:NO];
        }
        [imgVwPlayPause setImage:[UIImage imageNamed:strImageName]];
    }
}

- (void)hidePlayPauseButton {
    NSDate *dateNow = [NSDate date];
    NSTimeInterval timeInterval = [dateNow timeIntervalSinceDate:dateToHide];
    if (timeInterval > 0) {
        if ([avPlayer rate] > 0.5)
            [imgVwPlayPause setHidden:YES];
    }
}

#pragma mark - Resign Responders

- (void)resignResponders {
    [scrlView setContentOffset:CGPointMake(0, 0) animated:YES];
    [txtFieldCaption resignFirstResponder];
}

#pragma mark - Posting Image on Parse

- (void)postTheFile:(UIBarButtonItem *)sender {
    
    if (imgCaptured) {
        
        PFUser *currentUser = [PFUser currentUser];
        
        if (currentUser) {
            
            viewLoading = [_DPFunctions showLoadingViewWithText:@"Posting..." inView:self.view];
            
            NSString *userID = currentUser.objectId;
            NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
            NSString *imageFileName = [NSString stringWithFormat:@"%@-%f.png", userID, timeInterval];
            
            NSData *imageData = UIImagePNGRepresentation(imgCaptured.image);
            PFFile *imageFile = [PFFile fileWithName:imageFileName data:imageData];
            [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                
                PFObject *userPhoto = [PFObject objectWithClassName:@"Post"];
                userPhoto[@"fileDesc"] = txtFieldCaption.text;
                userPhoto[@"filePosted"] = imageFile;
                userPhoto[@"fileImage"] = imageFile;
                userPhoto[@"fileUsername"] = currentUser.username;
                userPhoto[@"fileUserID"] = currentUser.objectId;
                userPhoto[@"fileUserEmail"] = currentUser.email;
                userPhoto[@"fileType"] = [NSNumber numberWithInt:PostTypeImage];
                userPhoto[@"userPointer"] = currentUser;
                //            [userPhoto setObject:currentUser forKey:@"fileUser"];
                [userPhoto saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    
                    [_DPFunctions hideLoadingView:viewLoading];
                    
                    NSString *strTitle = @"";
                    NSString *strMessage = @"";
                    if (!error) {
                        strTitle = @"Posted";
                        strMessage = @"The image posted successfully on server";
                    }
                    else {
                        strTitle = @"Error";
                        strMessage = @"The image can't be posted on server right now";
                    }
                    
                    NSString *otherTitle = (!error) ? nil : @"Retry";
                    NSString *cancelTitle = (!error) ? @"OK" : @"Cancel";
                    
                    [[[UIAlertView alloc] initWithTitle:strTitle
                                                message:strMessage
                                               delegate:self
                                      cancelButtonTitle:cancelTitle
                                      otherButtonTitles:otherTitle, nil] show];
                }];
            }
                                   progressBlock:^(int percentDone) {
                                       [progressUpload setProgress:percentDone/100.f];
                                   }];
        }
    }
    else {
        [self generateImageForVideoAtURL:self.urlVideo];
    }
}

#pragma mark - Generating Image

-(void)generateImageForVideoAtURL:(NSURL *)urlVideo {
    
    AVURLAsset *asset=[[AVURLAsset alloc] initWithURL:urlVideo options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform=TRUE;
    
    CMTime thumbTime = CMTimeMakeWithSeconds(0,30);
    
    AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        if (result != AVAssetImageGeneratorSucceeded) {
            NSLog(@"couldn't generate thumbnail, error:%@", error);
        }
        imgVideoThumb = [UIImage imageWithCGImage:im];
        dispatch_async(dispatch_get_main_queue(), ^ {
            [self uploadImageForMovie];
        });
    };
    
    CGSize maxSize = CGSizeMake(320, 180);
    generator.maximumSize = maxSize;
    [generator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:thumbTime]] completionHandler:handler];
}

#pragma mark - Upload Image For Movie

- (void)uploadImageForMovie {
    
    PFUser *currentUser = [PFUser currentUser];
    
    viewLoading = [_DPFunctions showLoadingViewWithText:@"Posting..." inView:self.view];
    
    NSString *userID = currentUser.objectId;
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
    fileName = [NSString stringWithFormat:@"%@-%f", userID, timeInterval];
    NSString *imageFileName = [NSString stringWithFormat:@"%@.png", fileName];
    
    NSData *imageData = UIImagePNGRepresentation(imgVideoThumb);
    PFFile *imageFile = [PFFile fileWithName:imageFileName data:imageData];
    [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error)
            fileImage = imageFile;
        else
            NSLog(@"Image not uploaded");
        
        [self uploadMovieOnServer];
    }];
}

- (void)uploadMovieOnServer {
    
    PFUser *currentUser = [PFUser currentUser];
    
    if (currentUser) {
        
        NSString *imageFileName = [NSString stringWithFormat:@"%@.mov", fileName];
        
        NSString *pathForFile = [[NSBundle mainBundle] pathForResource:@"2minute" ofType:@"mov"];
        NSData *movieData = [NSData dataWithContentsOfFile:pathForFile];
        PFFile *movieFile = [PFFile fileWithName:imageFileName data:movieData];
        [movieFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            
            PFObject *userMovie = [PFObject objectWithClassName:@"Post"];
            userMovie[@"fileDesc"] = @"First Movie";
            userMovie[@"filePosted"] = movieFile;
            userMovie[@"fileImage"] = fileImage;
            userMovie[@"fileUsername"] = currentUser.username;
            userMovie[@"fileUserID"] = currentUser.objectId;
            userMovie[@"fileUserEmail"] = currentUser.email;
            userMovie[@"userPointer"] = currentUser;
            userMovie[@"fileType"] = [NSNumber numberWithInt:PostTypeVideo];
            [userMovie saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                
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

#pragma mark - Text Field Delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [scrlView setContentOffset:CGPointMake(0, 180) animated:YES];
}

#pragma mark - IBAction Play/Pause Button

- (IBAction)buttonPlayPauseAction:(id)sender {
    
    dateToHide = [NSDate date];
    NSString *strImageName = @"play";
    if ([avPlayer rate] >= 0.5) {
        strImageName = @"play";
        [avPlayer pause];
    }
    else {
        strImageName = @"pause";
        [avPlayer play];
    }
    [imgVwPlayPause setImage:[UIImage imageNamed:strImageName]];
    [self performSelector:@selector(hidePlayPauseButton)
               withObject:nil
               afterDelay:4];
}

#pragma mark - UIAlertView Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *strTitle = [alertView buttonTitleAtIndex:buttonIndex];
    if ([strTitle isEqualToString:@"OK"]) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    else if ([strTitle isEqualToString:@"Retry"]) {
        [self postTheFile:rightBarButtonItem];
    }
}

@end
