//
//  UserCell.m
//  DonkPlanet
//
//  Created by Varun on 18/02/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import "UserCell.h"

@interface UserCell () {
    
    __weak IBOutlet UILabel *lblUsername;
    __weak IBOutlet UIButton *btnFollow;
    __weak IBOutlet UIActivityIndicatorView *activityLoader;
    PFUser *thisCellUser;
}

@end

@implementation UserCell

- (void)awakeFromNib {
    // Initialization code
    [btnFollow.layer setCornerRadius:4.f];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Check User Status

- (void)checkUserStatusWithUser:(PFUser *)user {
    
    [UIView animateWithDuration:0.15f
                     animations:^ {
                         [btnFollow setFrame:CGRectMake(37.5, 10, 0, 0)];
                     }
                     completion:^(BOOL finished) {
                         [activityLoader startAnimating];
                     }];
    
    PFUser *currentUser = [PFUser currentUser];
    
    PFQuery *statusQuery = [PFQuery queryWithClassName:@"Follow"];
    [statusQuery whereKey:@"follower" equalTo:currentUser];
    [statusQuery whereKey:@"following" equalTo:user];
    [statusQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            NSInteger action = TypeFollow;
            if ([objects count])
                action = TypeFollowing;
            
            [self updateButtonForAction:action];
        }
        else {
            [activityLoader stopAnimating];
        }
    }];
}

#pragma mark - Filling Cells

- (void)updateButtonForAction:(NSInteger)action {
    
    NSString *txtButton = @"Follow";
    UIColor *colorButton = [_DPFunctions colorWithR:29 g:145 b:255 alpha:1.0f];
    if (action == TypeFollowing) {
        colorButton = [_DPFunctions colorWithR:44 g:188 b:0 alpha:1.0f];
        txtButton = @"Following";
    }
    
    [btnFollow setTag:action];
    
    [UIView animateWithDuration:0.15f
                          delay:0.0f
                        options:UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionAllowUserInteraction
                     animations:^ {
                         
                         [btnFollow setFrame:CGRectMake(0, 0, 75, 20)];
                         
                         [btnFollow setTitle:txtButton forState:UIControlStateNormal];
                         [btnFollow setTitleColor:colorButton forState:UIControlStateNormal];
                         
                         [btnFollow.layer setBorderColor:colorButton.CGColor];
                         [btnFollow.layer setBorderWidth:1.0f];
                     }
                     completion:^(BOOL finished) {
                         [activityLoader stopAnimating];
                     }];
}

- (void)fillUserCellForIndex:(PFUser *)user {

    thisCellUser = user;
    [lblUsername setText:user.username];
    [self checkUserStatusWithUser:user];
}

- (void)fillUserCellForFollower:(BOOL)follower
                  andUserObject:(PFObject *)thisObject {
    
    NSString *otherUser = follower ? @"follower" : @"following";
    
    thisCellUser = [thisObject objectForKey:otherUser];
    [lblUsername setText:thisCellUser.username];
    [self checkUserStatusWithUser:thisCellUser];
}

#pragma mark - IBAction Follow/ing

- (IBAction)buttonFollowFollowingAction:(UIButton *)sender {
    
    [activityLoader startAnimating];
    
    [UIView animateWithDuration:0.15f
                     animations:^ {
                         [btnFollow setFrame:CGRectMake(37.5, 10, 0, 0)];
                     }];
    
    PFUser *currentUser = [PFUser currentUser];
    
    PFObject *userFollow = [PFObject objectWithClassName:@"Follow"];
    [userFollow setObject:currentUser forKey:@"follower"];
    [userFollow setObject:thisCellUser forKey:@"following"];
    if ([sender tag] == TypeFollow) {
        [userFollow saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                [self updateButtonForAction:TypeFollowing];
            }
            else
                [activityLoader stopAnimating];
        }];
    }
    else if ([sender tag] == TypeFollowing) {
        [self deleteRelationBetweenUsers];
    }
}

- (void)deleteRelationBetweenUsers {
    
    PFQuery *query = [PFQuery queryWithClassName:@"Follow"];
    [query whereKey:@"follower" equalTo:[PFUser currentUser]];
    [query whereKey:@"following" equalTo:thisCellUser];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            for (PFObject *followUser in objects) {
                [followUser deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (succeeded){
                        [self updateButtonForAction:TypeFollow];
                        if ([self.delegate respondsToSelector:@selector(userUnFollowed)])
                            [self.delegate userUnFollowed];
                        NSLog(@"BOOOOOM"); // this is my function to refresh the data
                    } else {
                        NSLog(@"DELETE ERRIR");
                    }
                }];
            }
        }
    }];
}

@end
