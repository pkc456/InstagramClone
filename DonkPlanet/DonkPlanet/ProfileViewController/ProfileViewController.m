//
//  ProfileViewController.m
//  DonkPlanet
//
//  Created by Varun on 20/01/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import <AddressBook/AddressBook.h>

#import "ProfileViewController.h"
#import "InfoCell.h"

#import "CollectionPosts.h"
#import "UsersView.h"

@interface ProfileViewController () <UIAlertViewDelegate> {
    
    __weak IBOutlet UIImageView *imgProfile;
    __weak IBOutlet UILabel *lblName;
    __weak IBOutlet UILabel *lblEmail;
    __weak IBOutlet UIButton *btnPosts;
    __weak IBOutlet UIButton *btnFollowers;
    __weak IBOutlet UIButton *btnFollowing;
    __weak IBOutlet UIView *viewButtons;
    __weak IBOutlet UIView *viewExtension;
    __weak IBOutlet UIButton *btnContacts;
    
    NSMutableArray *arrPostsByUser;
    
    CollectionPosts *viewPostsCollection;
    UsersView *objUsersView;
    UsersView *objViewContacts;
    
    UIView *viewCurrent;
    NSArray *arrContacts;
    
    NSMutableArray *arrKnownUsers;
    NSMutableArray *arrFollowers;
    NSMutableArray *arrFollowing;
    
    BOOL boolFollowersFetched;
    BOOL boolFollowingFetched;
    
    BOOL errorFetchingFollowers;
    BOOL errorFetchingFollowing;
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self fetchFollowers];
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
    
    errorFetchingFollowers = NO;
    errorFetchingFollowing = NO;
    
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
    
    if (!objUsersView) {
        UINib *nibUsersView = [UINib nibWithNibName:@"UsersView" bundle:nil];
        UsersView *viewUsers = [[nibUsersView instantiateWithOwner:self options:nil] objectAtIndex:0];
        [viewUsers setFrame:CGRectMake(0, 0, viewExtension.frame.size.width, viewExtension.frame.size.height)];
        objUsersView = viewUsers;
        
        [viewExtension addSubview:objUsersView];
        [objUsersView setHidden:YES];
    }
}

#pragma mark - Set Attributed Text on Button

- (void)setAttributedText:(NSString *)txt
               withNumber:(NSInteger)number
                 onButton:(UIButton *)button {
    
    NSString *strUserCount = [NSString stringWithFormat:@"%d", number];
    if (!number)
        strUserCount = @"no";
        
    NSString *strFull = [NSString stringWithFormat:@"%@ %@", strUserCount, txt];
    if (number < 0)
        strFull = txt;
    
    NSMutableAttributedString *attrstr = [[NSMutableAttributedString alloc] initWithString:strFull];
    
    UIFont *fontNormal = [UIFont fontWithName:_DP_FontHelveticaNeueLight size:13];
    UIFont *fontHigh = [UIFont fontWithName:_DP_FontHelveticaNeueBold size:13];
    UIColor *colorText = [UIColor colorWithWhite:170/255.0f alpha:1.0f];
    
    NSDictionary *dictNormalText = [NSDictionary dictionaryWithObjectsAndKeys:
                                    fontNormal, NSFontAttributeName,
                                    colorText, NSForegroundColorAttributeName, nil];
    
    NSDictionary *dictHighText = [NSDictionary dictionaryWithObjectsAndKeys:
                                  fontHigh, NSFontAttributeName,
                                  colorText, NSForegroundColorAttributeName, nil];
    
    [attrstr setAttributes:(number ? dictHighText : dictNormalText)
                     range:[strFull rangeOfString:strUserCount]];
    [attrstr setAttributes:dictNormalText
                     range:[strFull rangeOfString:txt]];
    
    [button setAttributedTitle:attrstr
                      forState:UIControlStateNormal];
    attrstr = nil;
}

#pragma mark - Fetch Followers/Following/Known Users

- (void)fetchFollowers {
    
    PFUser *currentUser = [PFUser currentUser];
    
    PFQuery *followerQuery = [PFQuery queryWithClassName:@"Follow"];
    [followerQuery whereKey:@"following" equalTo:currentUser];
    [followerQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        boolFollowersFetched = YES;
        if (!error) {
            arrFollowers = [[NSMutableArray alloc] initWithArray:objects];
            [self setAttributedText:@"followers"
                         withNumber:objects.count
                           onButton:btnFollowers];
        }
        else {
            errorFetchingFollowers = YES;
            [self setAttributedText:@"followers"
                         withNumber:-1
                           onButton:btnFollowers];
        }
    }];
    
    PFQuery *followingQuery = [PFQuery queryWithClassName:@"Follow"];
    [followingQuery whereKey:@"follower" equalTo:currentUser];
    [followingQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        boolFollowingFetched = YES;
        if (!error) {
            arrFollowing = [[NSMutableArray alloc] initWithArray:objects];
            [self setAttributedText:@"following"
                         withNumber:objects.count
                           onButton:btnFollowing];
        }
        else {
            errorFetchingFollowing = YES;
            [self setAttributedText:@"following"
                         withNumber:-1
                           onButton:btnFollowing];
        }
    }];
}

- (void)fetchKnownUsers {
    
    PFUser *currentUser = [PFUser currentUser];
    
    PFQuery *knownQuery = [PFQuery queryWithClassName:@"_User"];
    [knownQuery whereKey:@"phone" containedIn:currentUser[@"contacts"]];
    [knownQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        BOOL errorOccured = YES;
        if (!error) {
            errorOccured = NO;
            if (arrKnownUsers) {
                [arrKnownUsers removeAllObjects];
                arrKnownUsers = nil;
            }
            arrKnownUsers = [[NSMutableArray alloc] initWithArray:objects];
            
            NSLog(@"objects : %@", objects);
        }
        
        [objViewContacts setFetched:YES];
        [objViewContacts setErrorFetch:errorOccured];
        [objViewContacts setFollowers:NO];
        [objViewContacts setArrayToShow:arrKnownUsers];
    }];
    
//    PFQuery *followQuery = [PFQuery queryWithClassName:@"Follow"];
//    [followQuery whereKey:@"follower" containedIn:currentUser[@"contacts"]];
//    [followQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
//        if (!error) {
//            NSLog(@"objects : %@", objects);
//        }
//    }];
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
            
            [self setAttributedText:@"posts"
                         withNumber:objects.count
                           onButton:btnPosts];
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
            [[[UIAlertView alloc] initWithTitle:@"Error"
                                        message:@"Unable to fetch any posts right now"
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil, nil] show];
            [self setAttributedText:@"posts"
                         withNumber:-1
                           onButton:btnPosts];
        }
    }];
    
}

#pragma mark - Get All Contacts

- (NSArray *)getAllContacts {
    
    CFErrorRef *error = nil;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, error);
    
    __block BOOL accessGranted = NO;
    if (ABAddressBookRequestAccessWithCompletion != NULL) { // we're on iOS 6
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            accessGranted = granted;
            dispatch_semaphore_signal(sema);
        });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        
    }
    else { // we're on iOS 5 or older
        accessGranted = YES;
    }
    
    if (accessGranted) {
        
#ifdef DEBUG
        NSLog(@"Fetching contact info ----> ");
#endif
        
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, error);
        ABRecordRef source = ABAddressBookCopyDefaultSource(addressBook);
        CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(addressBook, source, kABPersonSortByFirstName);
        CFIndex nPeople = ABAddressBookGetPersonCount(addressBook);
        NSMutableArray* items = [NSMutableArray arrayWithCapacity:nPeople];
        
        
        for (int i = 0; i < nPeople; i++)
        {
            NSMutableDictionary *dictContact = [[NSMutableDictionary alloc] init];
            
            ABRecordRef person = CFArrayGetValueAtIndex(allPeople, i);
            
            //get First Name and Last Name
            
            NSString *firstName = (__bridge NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
            
            NSString *lastName =  (__bridge NSString*)ABRecordCopyValue(person, kABPersonLastNameProperty);
            
            if (!firstName)
                firstName = @"";
            if (!lastName)
                lastName = @"";
            
            // get contacts picture, if pic doesn't exists, show standart one
            
            //            NSData  *imgData = (__bridge NSData *)ABPersonCopyImageData(person);
            //            contacts.image = [UIImage imageWithData:imgData];
            //            if (!contacts.image) {
            //                contacts.image = [UIImage imageNamed:@"NOIMG.png"];
            //            }
            //get Phone Numbers
            
            NSMutableArray *phoneNumbers = [[NSMutableArray alloc] init];
            
            ABMultiValueRef multiPhones = ABRecordCopyValue(person, kABPersonPhoneProperty);
            for(CFIndex i=0;i<ABMultiValueGetCount(multiPhones);i++) {
                
                CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(multiPhones, i);
                NSString *phoneNumber = (__bridge NSString *) phoneNumberRef;
                
                NSString *strOnlyNumbers = [[phoneNumber componentsSeparatedByCharactersInSet:
                                        [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                                       componentsJoinedByString:@""];
                
                [phoneNumbers addObject:strOnlyNumbers];
                
                //NSLog(@"All numbers %@", phoneNumbers);
                
            }
            
            
            //            [contacts setNumbers:phoneNumbers];
            
            //get Contact email
            
            //            NSMutableArray *contactEmails = [NSMutableArray new];
            //            ABMultiValueRef multiEmails = ABRecordCopyValue(person, kABPersonEmailProperty);
            //
            //            for (CFIndex i=0; i<ABMultiValueGetCount(multiEmails); i++) {
            //                CFStringRef contactEmailRef = ABMultiValueCopyValueAtIndex(multiEmails, i);
            //                NSString *contactEmail = (__bridge NSString *)contactEmailRef;
            //
            //                [contactEmails addObject:contactEmail];
            //                // NSLog(@"All emails are:%@", contactEmails);
            //
            //            }
            //
            //            [contacts setEmails:contactEmails];
            
            [dictContact setObject:firstName forKey:@"FirstName"];
            [dictContact setObject:lastName forKey:@"LastName"];
            [dictContact setObject:phoneNumbers forKey:@"PhoneNumbers"];
            
            
            [items addObject:dictContact];
            
            //NSLog(@"Person is: %@", contacts.firstNames);
            //NSLog(@"Phones are: %@", contacts.numbers);
            //NSLog(@"Email is:%@", contacts.emails);
        }
        
        NSMutableArray *arrNumbers = [[NSMutableArray alloc] init];
        for (int index = 0; index < [items count]; index ++) {
            NSDictionary *dictAtIndex = [items objectAtIndex:index];
            NSArray *arrPhoneNumbers = [dictAtIndex objectForKey:@"PhoneNumbers"];
            [arrNumbers addObjectsFromArray:arrPhoneNumbers];
        }
        
        NSMutableArray *uniqueArray = [NSMutableArray array];
        [uniqueArray addObjectsFromArray:[[NSSet setWithArray:arrNumbers] allObjects]];
        
        NSLog(@"Arr Numbers : %@", uniqueArray);
        return uniqueArray;
    }
    else {
        NSLog(@"Cannot fetch Contacts :( ");
        return NO;
    }
}

#pragma mark - IBActions

- (IBAction)buttonShowPostsAction:(id)sender {

    [self fetchUserPosts];
    if (!viewPostsCollection) {
        UINib *nibCollectionPosts = [UINib nibWithNibName:@"CollectionPosts" bundle:nil];
        CollectionPosts *objCollectionPosts = [[nibCollectionPosts instantiateWithOwner:self options:nil] objectAtIndex:0];
        
        viewPostsCollection = objCollectionPosts;
        [viewPostsCollection setPostsFetched:NO];
        [viewExtension addSubview:viewPostsCollection];
    }
    
    if (viewCurrent != viewPostsCollection) {
        [viewCurrent setHidden:YES];
        viewCurrent = viewPostsCollection;
    }
    
    [viewCurrent setHidden:NO];
}

- (IBAction)buttonShowFollowersAction:(id)sender {

    if (!objUsersView) {
        UINib *nibUsersView = [UINib nibWithNibName:@"UsersView" bundle:nil];
        UsersView *viewUsers = [[nibUsersView instantiateWithOwner:self options:nil] objectAtIndex:0];
        [viewUsers setFrame:CGRectMake(0, 0, viewExtension.frame.size.width, viewExtension.frame.size.height)];
        objUsersView = viewUsers;
        
        [viewExtension addSubview:objUsersView];
    }
    
    if (viewCurrent != objUsersView) {
        [viewCurrent setHidden:YES];
        viewCurrent = objUsersView;
    }
    
    NSMutableArray *arrToShow = ([sender tag] == 1) ? arrFollowers : arrFollowing;
    BOOL errorFetching = ([sender tag] == 1) ? errorFetchingFollowers : errorFetchingFollowing;
    BOOL usersFetched = ([sender tag] == 1) ? boolFollowersFetched : boolFollowingFetched;
    
    [(UsersView *)viewCurrent setFetched:usersFetched];
    [(UsersView *)viewCurrent setErrorFetch:errorFetching];
    [(UsersView *)viewCurrent setFollowers:([sender tag] == 1)];
    [(UsersView *)viewCurrent setArrayToShow:arrToShow];
    
    [viewCurrent setHidden:NO];
}

- (IBAction)btnLogoutAction:(id)sender {
    
    NSString *strLogout = @"Are you sure you want to logout?";
    UIAlertView *alertLogout = [[UIAlertView alloc] initWithTitle:@"Logout"
                                                          message:strLogout
                                                         delegate:self
                                                cancelButtonTitle:@"No"
                                                otherButtonTitles:@"Yes", nil];
    [alertLogout show];
}

- (IBAction)barButtonContactsTapped:(id)sender {

    [[self.navigationItem rightBarButtonItem] setEnabled:NO];
    [[self.navigationItem leftBarButtonItem] setEnabled:NO];
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    UIView *viewBack = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenSize.width, self.view.frame.size.height)];
    [viewBack setBackgroundColor:[UIColor colorWithWhite:0.f alpha:0.6f]];
    [viewBack setTag:1000];
    
    if (!objViewContacts) {
        UINib *nibUsersView = [UINib nibWithNibName:@"UsersView" bundle:nil];
        UsersView *viewUsers = [[nibUsersView instantiateWithOwner:self options:nil] objectAtIndex:0];
        [viewUsers setFrame:CGRectMake(10, 10, viewBack.frame.size.width - 20, viewBack.frame.size.height - 69)];
        objViewContacts = viewUsers;
        [objViewContacts.layer setCornerRadius:4.0f];
    }

    [viewBack addSubview:objViewContacts];
    [self fetchKnownUsers];
    
    UIButton *btnClose = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnClose setFrame:CGRectMake(screenSize.width - 26, 0, 24, 24)];
    [btnClose setBackgroundColor:[UIColor colorWithWhite:242/255.0f alpha:1.0f]];
    [btnClose setImage:[UIImage imageNamed:@"crossButton"]
              forState:UIControlStateNormal];
    [btnClose addTarget:self
                 action:@selector(closeKnownUserViewAction:)
       forControlEvents:UIControlEventTouchUpInside];
    [viewBack addSubview:btnClose];
    [btnClose.layer setCornerRadius:12];
    
    [self.view addSubview:viewBack];
}

- (IBAction)closeKnownUserViewAction:(UIButton *)sender {

    [[self.navigationItem rightBarButtonItem] setEnabled:YES];
    [[self.navigationItem leftBarButtonItem] setEnabled:YES];
    
    UIView *viewBack = [self.view viewWithTag:1000];
    [viewBack.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [viewBack removeFromSuperview];
    viewBack = nil;
}

#pragma mark - UIAlertView Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

    if (buttonIndex) {
        [PFUser logOut];
        self.tabBarController.selectedIndex = 0;
    }
}

@end
