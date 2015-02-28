//
//  UsersView.m
//  DonkPlanet
//
//  Created by Varun on 12/02/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import "UsersView.h"
#import "UserCell.h"

static NSString *REUSEUserCell = @"REUSEUserCell";

@interface UsersView () <UITableViewDataSource, UITableViewDelegate, UserCellUnFollow> {
    
    __weak IBOutlet UILabel *lblNothing;
    __weak IBOutlet UIActivityIndicatorView *activityLoading;
    __weak IBOutlet UITableView *tblView;
    
    NSMutableArray *arrToShow;
}

@end

@implementation UsersView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)awakeFromNib {
    
    UINib *tblCellNib = [UINib nibWithNibName:@"UserCell" bundle:nil];
    [tblView registerNib:tblCellNib forCellReuseIdentifier:REUSEUserCell];
    
    [tblView setSeparatorInset:UIEdgeInsetsMake(0, 5, 0, 5)];
    [tblView setLayoutMargins:UIEdgeInsetsMake(0, 5, 0, 5)];
}

- (void)setArrayToShow:(NSMutableArray *)arrUsers {
    
    if (self.fetched) {
        arrToShow = arrUsers;
        NSString *strMessageToShow = @"";
        if (self.followers) {
            if (self.errorFetch) {
                strMessageToShow = @"error fetching your followers..";
            }
            else if (![arrToShow count]) {
                strMessageToShow = @"no followers to show";
            }
        }
        else {
            if (self.errorFetch) {
                strMessageToShow = @"error fetching users you follow..";
            }
            else if (![arrToShow count]) {
                strMessageToShow = @"no users to show";
            }
        }
        if ([strMessageToShow length]) {
            [lblNothing setText:strMessageToShow];
            [lblNothing setHidden:NO];
        }
        else {
            [lblNothing setHidden:YES];
        }
    
        [tblView setHidden:![arrToShow count]];
        [activityLoading stopAnimating];
        arrToShow = arrUsers;
        [tblView reloadData];
    }
}

#pragma mark - User Cell Delegate

- (void)userUnFollowed {
    if ([self.delegate respondsToSelector:@selector(updateFollowingUsers)])
        [self.delegate updateFollowingUsers];
}

#pragma mark - UITableView Delegate and DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [arrToShow count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UserCell *objUserCell = (UserCell *)[tableView dequeueReusableCellWithIdentifier:REUSEUserCell forIndexPath:indexPath];
    [objUserCell setDelegate:self];
    if (self.deviceContacts) {
        [objUserCell fillUserCellForIndex:[arrToShow objectAtIndex:indexPath.row]];
    }
    else {
        [objUserCell fillUserCellForFollower:self.followers
                               andUserObject:[arrToShow objectAtIndex:indexPath.row]];
    }
//    [objUserCell fillUserCellForIndex:[arrToShow objectAtIndex:indexPath.row]];
    return objUserCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([self.delegate respondsToSelector:@selector(showProfileForUser:)]) {
        NSString *otherUser = self.followers ? @"followUserPointer" : @"followingUserPointer";
        PFObject *objectAtIndex = [arrToShow objectAtIndex:indexPath.row];
        [self.delegate showProfileForUser:(PFUser *)[objectAtIndex objectForKey:otherUser]];
    }
    
}

@end
