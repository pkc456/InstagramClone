//
//  UserCell.h
//  DonkPlanet
//
//  Created by Varun on 18/02/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UserCellUnFollow <NSObject>

- (void)userUnFollowed;

@end

@interface UserCell : UITableViewCell

@property (assign, nonatomic) id<UserCellUnFollow> delegate;

- (void)fillUserCellForIndex:(PFUser *)user;
- (void)fillUserCellForFollower:(BOOL)follower
                  andUserObject:(PFObject *)thisObject;

@end
