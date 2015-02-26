//
//  SearchCollectionCell.h
//  DonkPlanet
//
//  Created by Varun on 4/02/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchCollectionCell : UICollectionViewCell {
    
    __weak IBOutlet UIImageView *imgSearch;
    __weak IBOutlet UIImageView *imgPlay;
}

- (void)fillSearchCellWithObject:(PFObject *)objSearched;

@end
