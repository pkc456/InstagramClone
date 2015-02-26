//
//  InfoCell.m
//  DonkPlanet
//
//  Created by Varun on 3/02/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import "InfoCell.h"

@implementation InfoCell

- (void)awakeFromNib {
    // Initialization code
    [self setLayoutMargins:UIEdgeInsetsZero];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)fillCellInfoWithInfo:(NSString *)infoText
                     keyName:(NSString *)strKey {
    
    NSString *imgName = [[strKey componentsSeparatedByString:@"."] objectAtIndex:1];
    [lblInfo setText:infoText];
    [imgInfo setImage:[UIImage imageNamed:imgName]];
}

- (void)fillCellWithNews:(NSString *)txtNews {
    [lblInfo setText:txtNews];
    [imgInfo setImage:[UIImage imageNamed:@"small_thumb"]];
}

@end
