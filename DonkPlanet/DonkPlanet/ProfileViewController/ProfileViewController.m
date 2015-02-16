//
//  ProfileViewController.m
//  DonkPlanet
//
//  Created by Varun on 20/01/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import "ProfileViewController.h"
#import "InfoCell.h"

#import "CollectionPosts.h"

@interface ProfileViewController () {
    
    __weak IBOutlet UIImageView *imgProfile;
    __weak IBOutlet UILabel *lblName;
    __weak IBOutlet UILabel *lblEmail;
    __weak IBOutlet UIButton *btnPosts;
    __weak IBOutlet UIButton *btnFollowers;
    __weak IBOutlet UIButton *btnFollowing;
    __weak IBOutlet UIView *viewButtons;
    __weak IBOutlet UIView *viewExtension;
    
    NSMutableArray *arrPostsByUser;
    
    CollectionPosts *viewPostsCollection;
}

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.navigationItem setTitle:@"Profile"];
    [self setupProfileView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self buttonShowPostsAction:btnPosts];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Setup View

- (void)setupProfileView {
    
    [imgProfile.layer setBorderColor:[UIColor colorWithWhite:220/255.0f alpha:1.0f].CGColor];
    [imgProfile.layer setBorderWidth:3.0f];
    [imgProfile.layer setCornerRadius:imgProfile.frame.size.width/2];
    
    CGColorRef borderColor = [UIColor colorWithWhite:200/255.0f alpha:1.0f].CGColor;
    
    [viewButtons.layer setBorderWidth:0.5f];
    [viewButtons.layer setBorderColor:borderColor];
    
    for (UIButton *button in viewButtons.subviews) {
        [button.layer setBorderColor:borderColor];
        [button.layer setBorderWidth:0.25];
    }
    
    PFUser *currentUser = [PFUser currentUser];
    [lblName setText:currentUser[@"username"]];
    [lblEmail setText:currentUser[@"email"]];
    PFFile *fileImage = currentUser[@"profileImage"];
    [fileImage getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (!error) {
            [imgProfile setImage:[UIImage imageWithData:data]];
        }
    }];
}

#pragma mark - Fetch User Posts

- (void)fetchUserPosts {
    
    PFQuery *query = [PFQuery queryWithClassName:@"Post"];
    [query whereKey:@"userPointer" equalTo:[PFUser currentUser]];
    [query orderByDescending:@"createdAt"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        [viewPostsCollection setPostsFetched:YES];
        if (!error) {
            // The find succeeded.
            NSLog(@"Successfully retrieved %d scores.", objects.count);
            // Do something with the found objects
            arrPostsByUser = nil;
            arrPostsByUser = [[NSMutableArray alloc] initWithArray:objects];
            [viewPostsCollection setArrayToShow:arrPostsByUser];
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
            [[[UIAlertView alloc] initWithTitle:@"Error"
                                        message:@"Unable to fetch any posts right now"
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil, nil] show];
        }
    }];

}

#pragma mark - IBActions

- (IBAction)buttonShowPostsAction:(id)sender {
//    if (viewSpotsOrMembersTable) {
//        [viewSpotsOrMembersTable removeFromSuperview];
//        viewSpotsOrMembersTable = nil;
//    }
    [self fetchUserPosts];
    if (!viewPostsCollection) {
        UINib *nibCollectionPosts = [UINib nibWithNibName:@"CollectionPosts" bundle:nil];
        CollectionPosts *objCollectionPosts = [[nibCollectionPosts instantiateWithOwner:self options:nil] objectAtIndex:0];
        
        viewPostsCollection = objCollectionPosts;
        [viewPostsCollection setPostsFetched:NO];
    }
//    [viewPostsCollection setDelegate:self];
    [viewExtension addSubview:viewPostsCollection];
    
//    if (viewCurrent != viewSpotsCollection) {
//        [viewCurrent setHidden:YES];
//        [viewSpotsCollection setHidden:NO];
//        [viewContainer addSubview:viewSpotsCollection];
//    }
//    viewCurrent = viewSpotsCollection;
}

- (IBAction)buttonShowFollowersAction:(id)sender {
}

- (IBAction)buttonShowFollowingAction:(id)sender {
}

- (IBAction)btnLogoutAction:(id)sender {
    [PFUser logOut];
    self.tabBarController.selectedIndex = 0;
}

@end
