//
//  UserCell.h
//  DonkPlanet
//
//  Created by Varun on 18/02/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserCell : UITableViewCell

- (void)fillUserCellForIndex:(PFUser *)user;
- (void)fillUserCellForFollower:(BOOL)follower
                  andUserObject:(PFObject *)thisObject;

@end
