//
//  PostViewController.m
//  DonkPlanet
//
//  Created by Varun on 26/02/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "PostViewController.h"

@interface PostViewController () {
    __weak IBOutlet UIImageView *imgViewProfile;
    __weak IBOutlet UILabel *lblUsername;
    __weak IBOutlet UILabel *lblTime;
    __weak IBOutlet UIImageView *imgViewPost;
    __weak IBOutlet UILabel *lblCaption;
    __weak IBOutlet UILabel *lblEmail;
    __weak IBOutlet UIView *viewVideo;
    __weak IBOutlet UIButton *btnPlayPause;
    __weak IBOutlet UIImageView *imgViewPlayPause;
    
    AVPlayer *avPlayer;
    NSDate *dateToHide;
}

@end

@implementation PostViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupPostDefaults];
    [self setupPostInfo];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [avPlayer pause];
    @try {
        [avPlayer removeObserver:self forKeyPath:@"rate" context:nil];
    }
    @catch (NSException *exception) {
        NSLog(@"No observer for player");
    }
    @finally {
        avPlayer = nil;
        for (AVPlayerLayer *avLayer in viewVideo.layer.sublayers) {
            [avLayer setPlayer:nil];
            [avLayer removeFromSuperlayer];
        }
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Setup View Defaults

- (void)setupPostDefaults {
    
    [imgViewProfile.layer setBorderColor:[UIColor lightGrayColor].CGColor];
    [imgViewProfile.layer setBorderWidth:0.5f];
    
    [imgViewPost.layer setBorderColor:[UIColor lightGrayColor].CGColor];
    [imgViewPost.layer setBorderWidth:1.0f];
}

- (void)setupPostInfo {
    
    [lblTime setText:[_DPFunctions setTimeElapsedForDate:self.objPost.createdAt]];
    
    PFUser *user = [self.objPost objectForKey:@"userPointer"];
    
    [self setTitle:user.username];
    [lblUsername setText:user.username];
    [lblEmail setText:user.email];
    
    PFFile *userImage = user[@"profileImage"];
    [userImage getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (!error)
            [imgViewProfile setImage:[UIImage imageWithData:data]];
    }];
    
    [lblCaption setText:[self.objPost objectForKey:@"fileDesc"]];
    
    BOOL isImage = ([[self.objPost objectForKey:@"fileType"] intValue] == PostTypeImage);
    [self hideMovieControls:isImage];
    
    if (!isImage) {
        
        PFFile *fileVideo = [self.objPost objectForKey:@"filePosted"];
        
        NSURL *fileURL = [NSURL URLWithString:fileVideo.url];
        if (!avPlayer) {
        
            avPlayer = [[AVPlayer alloc] initWithURL:fileURL];
            
            AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:avPlayer];
            avPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
            layer.frame = CGRectMake(0, 0, viewVideo.frame.size.width, viewVideo.frame.size.height);
            [viewVideo.layer addSublayer: layer];
            
            [avPlayer addObserver:self forKeyPath:@"rate" options:0 context:nil];
        }
        else {
            [avPlayer pause];
        }
    }
    else {
        BOOL toAdd = YES;
        for (UIView *gmdView in imgViewPost.subviews) {
            if ([gmdView isKindOfClass:[GMDCircleLoader class]]) {
                toAdd = NO;
                break;
            }
        }
        if (toAdd)
            [GMDCircleLoader setOnView:imgViewPost withTitle:@"..." animated:YES];
        PFFile *fileImage = [self.objPost objectForKey:@"filePosted"];
        [fileImage getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if (!error) {
                [imgViewPost setImage:[UIImage imageWithData:data]];
                [GMDCircleLoader hideFromView:imgViewPost animated:YES];
            }
        }];
    }
}

- (void)hideMovieControls:(BOOL)toHide {
    
    [imgViewPost setHidden:!toHide];
    [imgViewPlayPause setHidden:toHide];
    [viewVideo setHidden:toHide];
    [btnPlayPause setHidden:toHide];
}

- (void)hidePlayPauseButton {
    NSDate *dateNow = [NSDate date];
    NSTimeInterval timeInterval = [dateNow timeIntervalSinceDate:dateToHide];
    if (timeInterval > 0) {
        if ([avPlayer rate] > 0.5)
            [imgViewPlayPause setHidden:YES];
    }
}

- (IBAction)buttonPlayPauseTouched:(UIButton *)sender {
    
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
    [imgViewPlayPause setImage:[UIImage imageNamed:strImageName]];
    [self performSelector:@selector(hidePlayPauseButton)
               withObject:nil
               afterDelay:4];
}

#pragma mark - Observe key value path AVPlayer

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"rate"]) {
        dateToHide = [NSDate date];
        NSString *strImageName = @"";
        if ([avPlayer rate] > 0.5) {
            strImageName = @"pause";     // This changes the button to Pause
        }
        else {
            strImageName = @"play";    // This changes the button to Play
            [imgViewPlayPause setHidden:NO];
        }
        [imgViewPlayPause setImage:[UIImage imageNamed:strImageName]];
    }
}

@end
