//
//  ProfileViewController.m
//  Message
//
//  Created by 杨朋亮 on 14-9-13.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import "ProfileViewController.h"

#import "UserPresent.h"
#import "APIRequest.h"
#import "UserDB.h"

#import "MBProgressHUD.h"

#import "UIImage+Resize.h"

#import "CustomStatusViewController.h"


#import "MainTabBarController.h"
#import "AppDelegate.h"

@interface ProfileViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *headView;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UIButton *statusBtn;
@property (weak, nonatomic) IBOutlet UIView *netStatusArea;

@property  (nonatomic)               UIBarButtonItem *nextButton;

@end

@implementation ProfileViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setTitle:@"个人资讯"];
    
    [self.headView setUserInteractionEnabled: YES];
    
    if ([UserPresent instance].avatarURL) {
        
        NSURL *headUrl = [[NSURL alloc] initWithString:[UserPresent instance].avatarURL];
        [self.headView setImageWithURL:headUrl];
    
    }else{
        [self.headView setImage:[UIImage imageNamed:@"BrdtAttachContact"]];
    }
    if (self.editorState == ProfileEditorSettingType) {
        
        [self.netStatusArea setHidden:NO];
        
        if ([UserPresent instance].state.length > 0) {
            
            [self.statusBtn setTitle:[UserPresent instance].state forState:UIControlStateNormal];
        }else{
            [self.statusBtn setTitle:@"~没有状态~" forState:UIControlStateNormal];
        }
        
    }else if(self.editorState == ProfileEditorLoginingType){
        
        [self.netStatusArea setHidden: YES];
        self.nextButton = [[UIBarButtonItem alloc]
                           initWithTitle:@"下一步"
                           style:UIBarButtonItemStylePlain
                           target:self
                           action:@selector(nextAction)];
        [self.navigationItem setRightBarButtonItem:self.nextButton];
        [self.nextButton setEnabled:YES];
    }

}

- (void) viewWillAppear:(BOOL)animated{
    if ([UserPresent instance].state.length > 0) {
        
        [self.statusBtn setTitle:[UserPresent instance].state forState:UIControlStateNormal];
    }else{
        [self.statusBtn setTitle:@"~没有状态~" forState:UIControlStateNormal];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction) editorHeadAction:(id)sender{
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate  = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:picker animated:YES completion:NULL];
    
}

- (void) nextAction{
    UITabBarController *tabController = [[MainTabBarController alloc] init];
    UINavigationController *navCtl = [[UINavigationController alloc] initWithRootViewController:tabController];
    navCtl.navigationBarHidden = YES;
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    delegate.tabBarController = tabController;
    delegate.window.rootViewController = navCtl;

}

-(IBAction) editorNameAction:(id)sender{
  
    
}

-(IBAction)editorStatus:(id)sender{
   
    CustomStatusViewController * ctr = [[CustomStatusViewController alloc] init];
   [self.navigationController pushViewController:ctr animated: YES];
}


- (IBAction)onTap:(id)sender
{
    [self.nameTextField   resignFirstResponder];
}

#pragma mark- UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self animateTextField:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self animateTextField:NO];
}


- (void)animateTextField:(BOOL)up
{
    const int movementDistance = 50;
    const float movementDuration = 0.3f;
    
    int movement = (up ? -movementDistance : movementDistance);
    
    [UIView beginAnimations: @"anim" context: nil];
    
    [UIView setAnimationBeginsFromCurrentState: YES];
    
    [UIView setAnimationDuration: movementDuration];
    
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    
    [UIView commitAnimations];
    
}
-(void) updateAvatar:(UIImage*)img theURL:(NSString*) url theMBHud:(MBProgressHUD*)hud{
    [APIRequest  updateAvatar:url
                      success:^{
                          NSLog(@"updateAvatar success url:%@", url);
                          [[SDImageCache sharedImageCache] storeImage:img forKey: url];
                          [self.headView setImage: img];
                          
                          [UserPresent instance].avatarURL =  url;
                          [[UserDB instance] addUser: [UserPresent instance]];
                          [hud hide:NO];
                        }
                         fail:^{
                            NSLog(@"updateAvatar success url:%@", url);
                            [hud hide:NO];
                         }];
    
    
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo{
    NSLog(@"Chose image!  Details:  %@", image);
    CGSize size = CGSizeMake(120, 120);
    UIImage *sizeImg = [image resizedImage:size interpolationQuality: kCGInterpolationDefault];
    
   MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [APIRequest uploadImage:sizeImg
                    success:^(NSString *url) {
                        if([url length] > 0){
                            NSLog(@"upload image success url:%@", url);
                            [self updateAvatar:image theURL:url theMBHud:hud];
                        } else {
                            NSLog(@"upload image fail");
                            [hud hide:NO];
                        }
                    }
                       fail:^() {
                           NSLog(@"upload image fail");
                           [hud hide:NO];
                       }];
    
    [self dismissViewControllerAnimated:YES completion:NULL];

}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    
    [self dismissViewControllerAnimated:YES completion:NULL];
    
}

@end
