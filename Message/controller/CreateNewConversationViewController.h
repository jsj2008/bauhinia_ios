//
//  CreateNewConversationViewController.h
//  Message
//
//  Created by daozhu on 14-7-13.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ABContact.h"
#import "ContactDB.h"

@interface CreateNewConversationViewController : UIViewController< UITableViewDelegate, UITableViewDataSource,
ABPersonViewControllerDelegate, UISearchBarDelegate,
ContactDBObserver> {
    
}
@end
