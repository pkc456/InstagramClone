//
//  SignUpViewController.m
//  DonkPlanet
//
//  Created by Varun on 20/01/2015.
//  Copyright (c) 2015 Channi. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import "SignUpViewController.h"

@interface SignUpViewController () <UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    
    __weak IBOutlet UIImageView *imgViewProfile;
    __weak IBOutlet DPTextField *txtFieldEmail;
    __weak IBOutlet DPTextField *txtFieldUsername;
    __weak IBOutlet DPTextField *txtFieldPassword;
    __weak IBOutlet DPTextField *txtFieldPhone;
    __weak IBOutlet UIButton *btnSignUp;
    __weak IBOutlet UITextView *txtViewPolicy;
    
    UIView *viewLoading;
    BOOL toUploadImage;
    BOOL photoUploaded;
    
    NSArray *arrContacts;
}

@end

@implementation SignUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupSignUpView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (void)setupSignUpView {
    [self setTitle:@"Sign Up"];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    [btnSignUp setBackgroundColor:[_DPFunctions colorWithR:36 g:164 b:193 alpha:1.0f]];
    [btnSignUp.layer setCornerRadius:3.0f];
    
    [imgViewProfile.layer setBorderColor:[UIColor colorWithWhite:220/255.0f alpha:1.0f].CGColor];
    [imgViewProfile.layer setBorderWidth:3.0f];
    
    [imgViewProfile.layer setCornerRadius:imgViewProfile.frame.size.width/2.0f];
    
    arrContacts = [[NSArray alloc] initWithArray:[self getAllContacts]];
    NSLog(@"Arr Contacts : %@", arrContacts);
}

- (void)resetTextFields {
    [txtFieldEmail setText:nil];
    [txtFieldUsername setText:nil];
    [txtFieldPassword setText:nil];
    [txtFieldPhone setText:nil];
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
                [phoneNumbers addObject:phoneNumber];
                
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
        return items;
    }
    else {
        NSLog(@"Cannot fetch Contacts :( ");
        return NO;
    }
}

#pragma mark - Text Field Delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
}

#pragma mark - Check User Details

- (BOOL)checkPhoneNumber:(NSString *)phoneNumber {
    
    NSError *error = NULL;
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypePhoneNumber error:&error];
    
    NSRange inputRange = NSMakeRange(0, [phoneNumber length]);
    NSArray *matches = [detector matchesInString:phoneNumber options:0 range:inputRange];
    
    BOOL verified = NO;

    if ([matches count] != 0) {
        // found match but we need to check if it matched the whole string
        NSTextCheckingResult *result = (NSTextCheckingResult *)[matches objectAtIndex:0];
        
        if ([result resultType] == NSTextCheckingTypePhoneNumber && result.range.location == inputRange.location && result.range.length == inputRange.length) {
            // it matched the whole string
            verified = YES;
        }
        else {
            // it only matched partial string
            verified = NO;;
        }
    }
    
    return verified;
}

- (NSString *)checkUserDetails {

    NSCharacterSet *whiteNewChars = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *email = [txtFieldEmail.text stringByTrimmingCharactersInSet:whiteNewChars];
    NSString *userName = [txtFieldUsername.text stringByTrimmingCharactersInSet:whiteNewChars];
    NSString *password = [txtFieldPassword.text stringByTrimmingCharactersInSet:whiteNewChars];
    NSString *phone = [txtFieldPhone.text stringByTrimmingCharactersInSet:whiteNewChars];
    
    BOOL phoneVerified = [self checkPhoneNumber:phone];
    
    NSString *message = @"";
    
    if (![_DPFunctions validateEmail:email]) {
        message = @"Email not valid";
    }
    if ([userName length] < 6) {
        if ([message length]) message = [NSString stringWithFormat:@"%@, ", message];
        message = [NSString stringWithFormat:@"%@Username must be atleast 6 charaters long", message];
    }
    if ([password length] < 6) {
        if ([message length]) message = [NSString stringWithFormat:@"%@, ", message];
        message = [NSString stringWithFormat:@"%@Password too short", message];
    }
    if (!phoneVerified) {
        if ([message length]) message = [NSString stringWithFormat:@"%@, ", message];
        message = [NSString stringWithFormat:@"%@Invalid phone number", message];
    }
    return message;
}

#pragma mark - Other Methods

- (void)signUpSuccess {
    
    [_DPFunctions hideLoadingView:viewLoading];
    [self resetTextFields];
    [self.navigationController popViewControllerAnimated:YES];

    NSString *message = @"User has been registred successfully.";
    if (!photoUploaded)
        message = [NSString stringWithFormat:@"%@. But profile image has not been uploaded yet.", message];
    
    [[[UIAlertView alloc] initWithTitle:@"Registered"
                                message:message
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil, nil] show];
    
}

- (void)checkIfToUploadImage {
    
    if (toUploadImage) {
        
        PFUser *currentUser = [PFUser currentUser];
        NSString *strImageName = [NSString stringWithFormat:@"%@.png", currentUser.objectId];
        
        NSData *imageData = UIImagePNGRepresentation(imgViewProfile.image);
        PFFile *imageFile = [PFFile fileWithName:strImageName data:imageData];
        [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                photoUploaded = YES;
                [currentUser setObject:imageFile forKey:@"profileImage"];
                [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (!error)
                        photoUploaded = YES;
                    else
                        photoUploaded = NO;
                    [self signUpSuccess];
                }];
            }
            else {
                photoUploaded = NO;
                [self signUpSuccess];
            }
        }];
    }
    
    /*
    if (toUploadImage) {
        
        PFUser *currentUser = [PFUser currentUser];
        NSString *strImageName = [NSString stringWithFormat:@"%@.png", currentUser.objectId];
        
        NSData *imageData = UIImagePNGRepresentation(imgViewProfile.image);
        PFFile *imageFile = [PFFile fileWithName:strImageName data:imageData];
        
        PFObject *userPhoto = [PFObject objectWithClassName:@"_User"];
        userPhoto[@"profileImage"] = imageFile;
//        [userPhoto saveInBackground];
        [userPhoto saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                photoUploaded = YES;
            }
            else {
                photoUploaded = NO;
            }
            [self signUpSuccess];
        }];
    }
    else {
        [self signUpSuccess];
    }
     */
}

#pragma mark - Sign Up IBAction

- (IBAction)buttonSignUpTouched:(id)sender {

    NSString *errorMessage = [self checkUserDetails];
    if (![errorMessage length]) {
        
        NSCharacterSet *whiteNewChars = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSString *email = [txtFieldEmail.text stringByTrimmingCharactersInSet:whiteNewChars];
        NSString *userName = [txtFieldUsername.text stringByTrimmingCharactersInSet:whiteNewChars];
        NSString *password = [txtFieldPassword.text stringByTrimmingCharactersInSet:whiteNewChars];
        NSString *phone = [txtFieldPhone.text stringByTrimmingCharactersInSet:whiteNewChars];
        
        PFUser *user = [PFUser user];
        [user setUsername:userName];
        [user setEmail:email];
        [user setPassword:password];
        user[@"phone"] = phone;
        
        viewLoading = [_DPFunctions showLoadingViewWithText:@"Registering" inView:self.view];
        
        [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            
            if (!error) {
                
                [self checkIfToUploadImage];
            }
            else {
                
                [_DPFunctions hideLoadingView:viewLoading];
                [[[UIAlertView alloc] initWithTitle:@"Register Problem"
                                            message:[error userInfo][@"error"]
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil, nil] show];
            }
        }];
    }
    else {
        [[[UIAlertView alloc] initWithTitle:@"Error"
                                    message:errorMessage
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil, nil] show];
    }
}

- (IBAction)buttonChoosePhotoTapped:(id)sender {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    else
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:NULL];
}

#pragma mark - UIImagePickerController Delegates

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    toUploadImage = YES;
    
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    imgViewProfile.image = chosenImage;
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

@end
