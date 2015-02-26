//
//  LoginViewController.m
//  DonkPlanet
//
//  Created by Varun on 20/01/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import "LoginViewController.h"
#import "SignUpViewController.h"

@interface LoginViewController () {
    
    __weak IBOutlet UITextField *txtFieldUsername;
    __weak IBOutlet UITextField *txtFieldPassword;
    __weak IBOutlet UIButton *btnLogin;
    __weak IBOutlet UIButton *btnSignUp;
    
    UIView *viewLoading;
}

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupLoginView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [txtFieldUsername setTextColor:[UIColor whiteColor]];
    [txtFieldPassword setTextColor:[UIColor whiteColor]];
}

//- (void) downloadVideo {
//    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://www.steppublishers.com/sites/default/files/step.mov"]];
//    NSString *tempPath = [NSString stringWithFormat:@"%@/temp.mov", NSTemporaryDirectory()];
//    [imageData writeToFile:tempPath atomically:YES];
//    UISaveVideoAtPathToSavedPhotosAlbum (tempPath, self, @selector(video:didFinishSavingWithError: contextInfo:), nil);
//}
//
//- (void)video:(NSString *)videoPath didFinishSavingWithError: (NSError *) error
//  contextInfo: (void *) contextInfo {
//    NSLog(@"Finished saving video with error: %@", error);
//}

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

- (void)setupLoginView {
    
    [txtFieldUsername setLeftViewMode:UITextFieldViewModeAlways];
    [txtFieldUsername setLeftView:[_DPFunctions leftViewForTextFieldWithImage:@"username"]];
    
    [txtFieldPassword setLeftViewMode:UITextFieldViewModeAlways];
    [txtFieldPassword setLeftView:[_DPFunctions leftViewForTextFieldWithImage:@"lock_white"]];
    
    [btnLogin setBackgroundColor:[_DPFunctions colorWithR:36 g:164 b:193 alpha:1.0f]];
    [btnLogin.layer setCornerRadius:3.0f];
    
    [btnSignUp setBackgroundColor:[_DPFunctions colorWithR:49 g:190 b:218 alpha:1.0f]];
    [btnSignUp.layer setCornerRadius:3.0f];
    [btnSignUp.layer setBorderColor:[UIColor colorWithWhite:0.9f alpha:0.8f].CGColor];
    [btnSignUp.layer setBorderWidth:1.0f];
}

#pragma mark - Check User Details

- (NSString *)checkUserDetails {
    
    NSCharacterSet *whiteNewChars = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *userName = [txtFieldUsername.text stringByTrimmingCharactersInSet:whiteNewChars];
    NSString *password = [txtFieldPassword.text stringByTrimmingCharactersInSet:whiteNewChars];
    
    NSString *message = @"";
    
    if ([userName length] < 6) {
        message = [NSString stringWithFormat:@"Username must be atleast 6 charaters long"];
    }
    if ([password length] < 6) {
        if ([message length]) message = [NSString stringWithFormat:@"%@, ", message];
        message = [NSString stringWithFormat:@"%@Password too short", message];
    }
    return message;
}

#pragma mark - Button IBActions

- (IBAction)buttonLoginTouched:(id)sender {
    
    NSString *errorMessage = [self checkUserDetails];
    if (![errorMessage length]) {
        
        NSCharacterSet *whiteNewChars = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSString *userName = [txtFieldUsername.text stringByTrimmingCharactersInSet:whiteNewChars];
        NSString *password = [txtFieldPassword.text stringByTrimmingCharactersInSet:whiteNewChars];
        
        viewLoading = [_DPFunctions showLoadingViewWithText:@"Processing" inView:self.view];
        [PFUser logInWithUsernameInBackground:userName password:password
                                        block:^(PFUser *user, NSError *error) {
                                            [_DPFunctions hideLoadingView:viewLoading];
                                            if (user) {
                                                [self dismissViewControllerAnimated:YES completion:nil];
                                                NSLog(@"User found");
                                                // Do stuff after successful login.
                                            } else {
                                                NSString *errMsg = [error userInfo][@"error"];
                                                [[[UIAlertView alloc] initWithTitle:@"Login Error"
                                                                            message:[errMsg capitalizedString]
                                                                           delegate:nil
                                                                  cancelButtonTitle:@"OK"
                                                                  otherButtonTitles:nil, nil] show];
                                                // The login failed. Check error to see why.
                                            }
                                        }];
    }
    else {
        [[[UIAlertView alloc] initWithTitle:@"Error"
                                    message:errorMessage
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil, nil] show];
    }
}

- (IBAction)buttonForgotPasswordTouched:(id)sender {
}

- (IBAction)buttonSignUpTouched:(id)sender {
    
}

@end
