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

#pragma mark - IBAction Follow/ing

- (IBAction)buttonFollowFollowingAction:(id)sender {
}

@end
