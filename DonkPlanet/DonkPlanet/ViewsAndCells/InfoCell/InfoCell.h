//
//  InfoCell.h
//  DonkPlanet
//
//  Created by Varun on 3/02/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfoCell : UITableViewCell {
    
    __weak IBOutlet UILabel *lblInfo;
    __weak IBOutlet UIImageView *imgInfo;
}

- (void)fillCellInfoWithInfo:(NSString *)infoText
                     keyName:(NSString *)strKey;
- (void)fillCellWithNews:(NSString *)txtNews;

@end
