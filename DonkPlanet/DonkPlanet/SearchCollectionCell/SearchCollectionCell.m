//
//  SearchCollectionCell.m
//  DonkPlanet
//
//  Created by Varun on 4/02/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import "SearchCollectionCell.h"

@implementation SearchCollectionCell

- (void)awakeFromNib {
    // Initialization code
    [imgSearch.layer setBorderColor:[UIColor colorWithWhite:180/255.0f alpha:0.4f].CGColor];
    [imgSearch.layer setBorderWidth:1.0f];
}

- (void)fillSearchCellWithObject:(PFObject *)objSearched {
    
    [imgSearch setImage:nil];
    PFFile *fileImage = [objSearched objectForKey:@"filePosted"];
    [fileImage getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (!error) {
            [imgSearch setImage:[UIImage imageWithData:data]];
        }
    }];
}

@end
