//
//  userPostsViewController.m
//  bookworm
//
//  Created by Raify Hidalgo on 4/27/17.
//  Copyright © 2017 nyu.edu. All rights reserved.
//

#import "userPostsViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface userPostsViewController ()

@end

@implementation userPostsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
- (IBAction)submitPost:(id)sender {
    self.ref = [[FIRDatabase database] reference];
    FIRUser *user = [FIRAuth auth].currentUser;
    if (user) {
        // Access users schema from database
        [[_ref child:@"users"]observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            
            // Snapshot of database objects for all users
            NSDictionary *currUserDict = snapshot.value;
            NSString* userID;
            
            // Find current user's ID
            for (NSString* key in currUserDict) {
                if ([[currUserDict[key] objectForKey:@"email"] isEqualToString:user.email]) {
                    userID = key;
                    NSLog(@"User Found");
                }
            }
            
            // Dictionary for all users posts
            NSMutableDictionary* posts;
            
            // If the user has made a post before
            if ([currUserDict[userID] objectForKey:@"posts"] != Nil) {
                posts = [currUserDict[userID] objectForKey:@"posts"];
                NSLog(@"User has post");
            } else { // User has never posted before - create posts object
                posts = [[NSMutableDictionary alloc] init];
                NSLog(@"User no Post");
            }
            // Use time to differentiate posts by user
            NSString* inputTime = [self getDate];
            [posts setObject:self.currentPostField.text forKey:inputTime];
            
            // Within the snapshot, set the updated post object
            [currUserDict[userID] setObject:posts forKey:@"posts"];
            
            // Within the database, set the updated snapshot
            [[[_ref child:@"users"] child:userID] setValue:currUserDict[userID]];
        } withCancelBlock:^(NSError * _Nonnull error) {
            NSLog(@"%@", error.localizedDescription);
        }];
        
        // Delay to allow database to update before attempting to retrieve again
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 1);
        
        [self alertUser:@"User Post" message:@"Message Submitted!"];
        
        dispatch_after(delay, dispatch_get_main_queue(), ^(void) {
             [self viewWillAppear:NO]; // Refresh view after user posts
        });
    }
    
}


-(void) viewWillAppear:(BOOL)animated {
    self.ref = [[FIRDatabase database] reference];
    FIRUser *user = [FIRAuth auth].currentUser;
    if (user) {
        [[_ref child:@"users"]observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            // Get database data for users schema
            NSDictionary *userDict = snapshot.value;
            NSString* idKey;
            
            // Setup array for all posts from all users
            NSMutableArray* allPosts = [[NSMutableArray alloc]init];
            
            // Loop through each user's unique Firebase key
            for (NSString* key in userDict) {
                // current user's key
                if ([userDict[key] containsObject:user.email]) {
                    idKey = key;
                }
                
                // If current user in loop has posts, get it, if not skip
                if ([userDict[key] objectForKey:@"posts"]) {
                    
                    // User's posts
                    NSDictionary* userPosts =[userDict[key] objectForKey:@"posts"];
                    
                    // Looping through posts of user
                    for (NSString* pk in userPosts) {
                        NSString* message =[userPosts objectForKey:pk];
                        NSString* time = pk;
                        NSString* username = [userDict[key] objectForKey:@"username"];
                        NSMutableDictionary* data = [[NSMutableDictionary alloc]init];
                        [data setObject:username forKey:@"username"];
                        [data setObject:message forKey:@"message"];
                        [data setObject:time forKey:@
                         "time"];
                        
                        // Add post details to the all posts array
                        [allPosts addObject:data];
                    }
                }
            }
            // Handle all the posts in the scroll view
            [self handlePosts:allPosts];
            
            // Get current users username for our label
            if (user.displayName != Nil) {
                self.usernameLabel.text = user.displayName;
            } else {
                self.usernameLabel.text =[NSString stringWithFormat:@"%@", [userDict[idKey] objectForKey:@"username"]];
            }
            
        } withCancelBlock:^(NSError * _Nonnull error) {
            NSLog(@"%@", error.localizedDescription);
        }];
    }

}

-(void) handlePosts:(NSMutableArray*) posts {
    self.scroll.bouncesZoom = YES;
    self.scroll.backgroundColor = [UIColor whiteColor];
    UIView* containerView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.scroll addSubview:containerView];
    CGFloat maximumWidth = 0.0;
    CGFloat totalHeight =  0.0;
    
    // Sort the users information based off of time
    for (int i = 0; i < [posts count] - 1;i++) {
        for (int j = 0; j < [posts count] - (i + 1); j++) {
            if ([[posts[j] objectForKey:@"time"] integerValue] < [[posts[j+1] objectForKey:@"time"] integerValue]) {
                NSMutableDictionary* tempI = posts[j];
                posts[j] = posts[j+1];
                posts[j+1] = tempI;
            }
        }
    }
    for (int i = 0; i < [posts count]; i++) {
        CGRect frame = CGRectMake(0, totalHeight, 250, 200);
        // Create text view to add to container
        UITextView* tview = [[UITextView alloc] initWithFrame:frame];
        
        // Handle formatting of text - username and message
        NSString* text = [NSString stringWithFormat:@"%@ \n \n %@ \n\n",[posts[i] objectForKey:@"username"],[posts[i] objectForKey:@"message"]];
        NSMutableParagraphStyle* ppStyle = [[NSMutableParagraphStyle alloc]init];
        ppStyle.alignment = NSTextAlignmentCenter;
        UIFont* ppFont = [UIFont fontWithName:@"Helvetica-Light" size:18];
        ppStyle.lineSpacing = 10;
        UIColor* ppColor = [UIColor blackColor];
        NSShadow* ppShadow = [[NSShadow alloc]init];
        [ppShadow setShadowColor:[UIColor colorWithRed:50.0/255.0 green:50.0/255.0 blue:50.0/255.0 alpha:0.5]];
        [ppShadow setShadowOffset:CGSizeMake(1.0, 1.0)];
        [ppShadow setShadowBlurRadius:1.5];
        
        // Create attributed text string
        NSAttributedString *postText = [[NSAttributedString alloc]initWithString:text attributes:@{NSParagraphStyleAttributeName:ppStyle, NSKernAttributeName:@2.0, NSFontAttributeName:ppFont, NSForegroundColorAttributeName:ppColor, NSShadowAttributeName:ppShadow}];
        
        tview.attributedText = postText;
        tview.backgroundColor = [UIColor colorWithRed:255 green:251 blue:241 alpha:1];
        tview.showsVerticalScrollIndicator = YES;
        
        // Don't allow users to edit text
        tview.editable = NO;
        
        // Add text view to container
        [containerView addSubview:tview];
        
        // Increment maximum width & total height
        maximumWidth = MAX(maximumWidth, tview.contentSize.width);
        totalHeight += tview.contentSize.height;
        UIBezierPath* linePath = [UIBezierPath bezierPath];
        [linePath moveToPoint:CGPointMake(0, totalHeight)];
        [linePath addLineToPoint:CGPointMake(maximumWidth, totalHeight)];
        CAShapeLayer* lineShape = [CAShapeLayer layer];
        lineShape.path = [linePath CGPath];
        lineShape.strokeColor = [[UIColor grayColor]CGColor];
        lineShape.lineWidth = 3.0;
        lineShape.fillColor = [[UIColor grayColor]CGColor];
        [containerView.layer addSublayer: lineShape];
        
    }
    // Size the container view and update the scroll view size
    containerView.frame = CGRectMake(0, 0, maximumWidth, totalHeight);
    containerView.center = self.scroll.center;
    self.scroll.contentSize = containerView.frame.size;
    // Minimum and maximum zoom scales
    self.scroll.minimumZoomScale = self.scroll.frame.size.width / maximumWidth;
    self.scroll.maximumZoomScale = 4.0;
    
    
    // Clear message area
    self.currentPostField.text = @"";
}



- (void)alertUser:(NSString *)title message:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *continueAction = [UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleDestructive handler:nil];
        [alert addAction:continueAction];
        [self presentViewController:alert animated: true completion: nil];
    });
}

- (IBAction)signOutPressed:(id)sender {
    NSError *signOutError;
    BOOL status = [[FIRAuth auth] signOut:&signOutError];
    if (!status) {
        NSLog(@"Error signing out: %@", signOutError);
        return;
    }
    NSLog(@"Logged Out");
}

-(NSString*) getDate { // Get current time in format - year - month - day - hour - min - seconds
    NSDate *date = [[NSDate alloc] init];
    NSString* time = [NSString stringWithFormat:@"%@", date];
    NSArray* arr = [time componentsSeparatedByString:@" "];
    NSArray* yymmdd = [arr[0] componentsSeparatedByString:@"-"];
    NSArray* hhmmss =[arr[1] componentsSeparatedByString:@":"];
    NSString* inputTime = [NSString stringWithFormat:@"%@%@%@%@%@%@",yymmdd[0],yymmdd[1],yymmdd[2], hhmmss[0],hhmmss[1],hhmmss[2]];
    return inputTime;
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

@end
