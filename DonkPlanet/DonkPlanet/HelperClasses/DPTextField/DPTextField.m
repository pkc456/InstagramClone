//
//  DPTextField.m
//  DonkPlanet
//
//  Created by Varun on 26/01/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import "DPTextField.h"

@implementation DPTextField

#pragma mark - Draw Rect

- (void)drawRect:(CGRect)rect {
    
    [self setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:18]];
    [self setTintColor:[UIColor lightGrayColor]];
    [self setBorderStyle:UITextBorderStyleNone];
    [self setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self setTextColor:[UIColor colorWithWhite:130/255.0f alpha:1.0f]];
    
    UIImage *imageBack = [UIImage imageNamed:@"txtFieldBack"];
    [self setBackground:imageBack];
    
    UIColor *color = [UIColor colorWithWhite:210/255.0f alpha:1.0f];
    self.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.placeholder attributes:@{NSForegroundColorAttributeName: color}];
    
    [self setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
    [self setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
}

@end
