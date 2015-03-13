//
//  HomeCell.m
//  DonkPlanet
//
//  Created by Varun on 27/01/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import "HomeCell.h"
#import <AVFoundation/AVFoundation.h>

@interface HomeCell () {
    
    __weak IBOutlet UIImageView *imgViewProfile;
    __weak IBOutlet UILabel *lblUsername;
    __weak IBOutlet UILabel *lblTime;
    __weak IBOutlet UIImageView *imgViewPost;
    __weak IBOutlet UILabel *lblCaption;
    __weak IBOutlet UILabel *lblEmail;
    __weak IBOutlet UIView *viewVideo;
    __weak IBOutlet UIButton *btnPlayPause;
    __weak IBOutlet UIImageView *imgViewPlayPause;
    
    NSDate *dateToHide;
    
    // Column Name for Tables
    NSString *poUserPointer;
    NSString *poFileDesc;
    NSString *poFilePosted;
    AVPlayer *avPlayer;
}

@end

@implementation HomeCell

- (void)awakeFromNib {
    // Initialization code
    poUserPointer = @"userPointer";
    poFileDesc = @"fileDesc";
    poFilePosted = @"filePosted";
    
    [imgViewProfile.layer setBorderColor:[UIColor lightGrayColor].CGColor];
    [imgViewProfile.layer setBorderWidth:0.5f];
    
    [imgViewPost.layer setBorderColor:[UIColor lightGrayColor].CGColor];
    [imgViewPost.layer setBorderWidth:1.0f];
    
    [viewVideo.layer setBorderColor:[UIColor lightGrayColor].CGColor];
    [viewVideo.layer setBorderWidth:1.0f];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)removeAVPlayer {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:[avPlayer currentItem]];
    
    if ([avPlayer rate] > 0.5) {
        [avPlayer pause];
        [avPlayer removeObserver:self forKeyPath:@"rate" context:nil];
        
        avPlayer = nil;
        for (AVPlayerLayer *avLayer in viewVideo.layer.sublayers) {
            [avLayer setPlayer:nil];
            [avLayer removeFromSuperlayer];
        }
    }
    
//    @try {
//        
//    }
//    @catch (NSException *exception) {
//        NSLog(@"No observer for player");
//    }
//    @finally {
//        
//    }
}

- (void)prepareForReuse {
    
    [imgViewPost setImage:[UIImage imageNamed:@"placeholder"]];
    [self removeAVPlayer];
}

#pragma mark - Filling Cell with post object

- (void)fillHomeCellWithWithObject:(PFObject *)objPost
                     withRowNumber:(NSInteger)rowNumber
              withLastPlayingIndex:(NSInteger)lastIndex {

    // Will be used when followers will be updated
    
//    NSArray *names = @[@"Jonathan Walsh",
//                       @"Dario Wunsch",
//                       @"Shawn Simon"];
//    [query whereKey:@"playerName" containedIn:names];
    
    [lblTime setText:[_DPFunctions setTimeElapsedForDate:objPost.createdAt]];
    
    PFUser *user = [objPost objectForKey:poUserPointer];
    
    [lblUsername setText:user.username];
    [lblEmail setText:user.email];

    PFFile *userImage = user[@"profileImage"];
    [userImage getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
    if (!error)
        [imgViewProfile setImage:[UIImage imageWithData:data]];
    }];
    
    [lblCaption setText:[objPost objectForKey:poFileDesc]];
    
    BOOL isImage = ([[objPost objectForKey:@"fileType"] intValue] == PostTypeImage);
    [self hideMovieControls:isImage];
    
    if (!isImage) {
        
        PFFile *fileVideo = [objPost objectForKey:poFilePosted];
        
        NSURL *fileURL = [NSURL URLWithString:fileVideo.url];
        if (!avPlayer) {
            [btnPlayPause setTag:rowNumber];
            
            avPlayer = [[AVPlayer alloc] initWithURL:fileURL];
        
            AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:avPlayer];
            avPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
            layer.frame = CGRectMake(0, 0, viewVideo.frame.size.width, viewVideo.frame.size.height);
            [viewVideo.layer addSublayer: layer];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(itemDidFinishPlaying:)
                                                         name:AVPlayerItemDidPlayToEndTimeNotification
                                                       object:[avPlayer currentItem]];
        }
        else {
            if (rowNumber != lastIndex) {
                CMTime startTime = CMTimeMakeWithSeconds(0, 1);
                [avPlayer seekToTime:startTime];
            }
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
        PFFile *fileImage = [objPost objectForKey:poFilePosted];
        [fileImage getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if (!error) {
                [imgViewPost setImage:[UIImage imageWithData:data]];
                [GMDCircleLoader hideFromView:imgViewPost animated:YES];
            }
        }];
    }
}

- (void)itemDidFinishPlaying:(NSNotification *) notification {
    // Will be called when AVPlayer finishes playing playerItem
    
    [avPlayer setRate:0.0f];
    AVPlayerItem *playerItem = [notification object];
    [playerItem seekToTime:kCMTimeZero];
}

#pragma mark - Hide Play/Pause Button

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

#pragma mark - Play Pause Button

- (IBAction)buttonPlayPauseTouched:(UIButton *)sender {
    
    [avPlayer addObserver:self forKeyPath:@"rate" options:0 context:nil];
    dateToHide = [NSDate date];
    NSString *strImageName = @"play";
    if ([avPlayer rate] >= 0.5) {
        strImageName = @"play";
        [avPlayer pause];
    }
    else {
        strImageName = @"pause";
        if ([self.delegate respondsToSelector:@selector(updateLastPlayingIndex:withSeekTime:)])
            [self.delegate updateLastPlayingIndex:sender.tag withSeekTime:0.0f];
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
