//
//  CaptureViewController.m
//  DonkPlanet
//
//  Created by Varun on 4/02/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import "CaptureViewController.h"

@interface CaptureViewController () <UIAlertViewDelegate> {
    
    __weak IBOutlet UIImageView *imgCaptured;
    __weak IBOutlet UIImageView *imgCaptionBack;
    __weak IBOutlet UITextField *txtFieldCaption;
    __weak IBOutlet UIProgressView *progressUpload;
    
    UIView *viewLoading;
    UIBarButtonItem *rightBarButtonItem;
}

@end

@implementation CaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupCaptureView];
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
    
    CGAffineTransform transform = CGAffineTransformMakeScale(1.0f, 5.0f);
    progressUpload.transform = transform;
    
    rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(postTheFile:)];
    [self.navigationItem setRightBarButtonItem:rightBarButtonItem animated:YES];
    
    [imgCaptured setImage:self.imageCaptured];
    
    UIImage *imageResized = [[UIImage imageNamed:@"captionback"] resizableImageWithCapInsets:UIEdgeInsetsMake(13, 13, 13, 13) resizingMode:UIImageResizingModeStretch];
    [imgCaptionBack setImage:imageResized];
}

#pragma mark - Posting Image on Parse

- (void)postTheFile:(UIBarButtonItem *)sender {

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
