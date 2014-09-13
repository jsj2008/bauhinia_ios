//
//  SettingViewController.h
//  Message
//
//  Created by daozhu on 14-6-16.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IMService.h"

@interface SettingViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,MessageObserver>

@property (strong,nonatomic) UITableView *tableView;
@property (strong,nonatomic) NSArray *cellTitleArray;
@property (weak,nonatomic) UITableViewCell *statusCell;

@end
