//
//  MessageViewController
//  Created by daozhu on 14-6-16.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import "MessageViewController.h"
#import "IMessage.h"
#import "IMService.h"
#import "UserPresent.h"
#import "MessageDB.h"
#import "ConversationHeadButtonView.h"
#import "MessageHeaderActionsView.h"
#import "MessageTableSectionHeaderView.h"

#import "MessageShowThePotraitViewController.h"

#define navBarHeadButtonSize 35



@interface MessageViewController () <JSMessagesViewDelegate, JSMessagesViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate>


@property (strong, nonatomic) NSMutableArray *messageArray;
@property (nonatomic,strong) UIImage *willSendImage;
@property (strong, nonatomic) NSMutableArray *timestamps;
@end

@implementation MessageViewController


-(id) initWithConversation:(Conversation *) con{
    if (self = [super init]) {
        self.currentConversation = con;
        
    }
    return self;
}

- (void)loadView{
    [super loadView];
    
    UIButton *imgButton = [[UIButton alloc] initWithFrame: CGRectMake(0,0,navBarHeadButtonSize,navBarHeadButtonSize)];
    
    [imgButton setImage: [UIImage  imageNamed:@"head1.png"] forState: UIControlStateNormal];
    [imgButton addTarget:self action:@selector(navBarUserheadAction) forControlEvents:UIControlEventTouchUpInside];
    
    CALayer *imageLayer = [imgButton layer];   //获取ImageView的层
    [imageLayer setMasksToBounds:YES];
    [imageLayer setCornerRadius:imgButton.frame.size.width/2];
    
    UIBarButtonItem *navBarHeadButton = [[UIBarButtonItem alloc] initWithCustomView: imgButton];
    
    self.navigationItem.rightBarButtonItem = navBarHeadButton;
    
    self.headButtonView = [[[NSBundle mainBundle]loadNibNamed:@"ConversationHeadButtonView" owner:self options:nil] lastObject];
    self.headButtonView.center = self.navigationController.navigationBar.center;
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.delegate = self;
    self.dataSource = self;
    if (!self.currentConversation.name) {
        
        self.title = @"消息";
    }else{
        self.title = self.currentConversation.name;
    }
    
    MessageHeaderActionsView *tableHeaderView = [[[NSBundle mainBundle]loadNibNamed:@"MessageHeaderActionsView" owner:self options:nil] lastObject];
    self.tableView.tableHeaderView = tableHeaderView;
    
    [self setBackgroundColor: [UIColor grayColor]];
    
    [self processConversationData];
    
    
    [[IMService instance] addMessageObserver:self];
}


#pragma mark - MessageObserver

-(void)onPeerMessage:(IMessage*)msg{
    [JSMessageSoundEffect playMessageReceivedSound];
    NSLog(@"receive msg:%@",msg);
    [self insertMsgToMessageBlokArray: msg];
    
    [self.tableView reloadData];
    [self scrollToBottomAnimated:YES];
}
//服务器ack
-(void)onPeerMessageACK:(int)msgLocalID uid:(int64_t)uid{
    NSLog(@"receive msg ack:%d",msgLocalID);
    
}

//接受方ack
-(void)onPeerMessageRemoteACK:(int)msgLocalID uid:(int64_t)uid{
    
}

-(void)onGroupMessage:(IMessage*)msg{
    
}
-(void)onGroupMessageACK:(int)msgLocalID gid:(int64_t)gid{
    
}

//用户连线状态
-(void)onOnlineState:(int64_t)uid state:(BOOL)on{
    
}

//对方正在输入
-(void)onPeerInputing:(int64_t)uid{
    
}

//同IM服务器连接的状态变更通知
-(void)onConnectState:(int)state{
    
    if (state == STATE_CONNECTING) {
        UIActivityIndicatorView *aiView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        aiView.hidesWhenStopped = NO; //I added this just so I could see it
        self.navigationItem.titleView = aiView;
    }else if(state == STATE_CONNECTED){
        
        self.navigationItem.titleView = self.headButtonView;
        
    }else if(state == STATE_CONNECTFAIL){
        [self.headButtonView.nameLabel setText: @"小张"];
        
        [self.headButtonView.conectInformationLabel setText:@"最近登录时间昨天下午"];
        
        self.navigationItem.titleView = self.headButtonView;
        
    }else{
        
        [self.headButtonView.nameLabel setText: @"小张"];
        [self.headButtonView.conectInformationLabel setText:@"最近登录时间昨天下午"];
        
        self.navigationItem.titleView = self.headButtonView;
        
    }
}

#pragma mark - UITextViewDelegate

-(void)textViewDidBeginEditing:(UITextView *)textView{
    [super textViewDidBeginEditing:textView];
    
    MessageInputing *inputing = [[MessageInputing alloc ] init];
    
    inputing.sender = [UserPresent instance].uid;
    inputing.receiver =self.currentConversation.cid;
    
    [[IMService instance] sendInputing: inputing];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.timestamps != nil) {
        return [self.timestamps count];
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.messageArray != nil) {
        
        NSMutableArray *array = [self.messageArray objectAtIndex: section];
        return [array count];
    }
    
    return 1;
}

#pragma mark -  UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    MessageTableSectionHeaderView *sectionView = [[[NSBundle mainBundle]loadNibNamed:@"MessageTableSectionHeaderView" owner:self options:nil] lastObject];
    NSDate *curtDate = [self.timestamps objectAtIndex: section];
    NSDate *todayDate = [NSDate date];
    NSString *timeStr = nil;
    if ([PublicFunc isTheDay:curtDate sameToThatDay:todayDate] ) {
        //当天
        int hour = [PublicFunc getHourComponentOfDate:curtDate];
        int minute = [PublicFunc getMinuteComponentOfDate:curtDate];
        int second = [PublicFunc getSecondeComponentOfDate:curtDate];
        timeStr = [NSString stringWithFormat:@"%d:%d:%D",hour,minute,second];
        sectionView.sectionHeader.text = timeStr;
        
    }else{
        int week = [PublicFunc getWeekDayComponentOfDate: curtDate];
        NSString *weekStr = [PublicFunc getWeekDayString: week];
        sectionView.sectionHeader.text = weekStr;
    }
    return sectionView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 44;
}

#pragma mark - Messages view delegate
- (void)sendPressed:(UIButton *)sender withText:(NSString *)text {
    
    IMessage *msg = [[IMessage alloc] init];
    
    msg.sender = [UserPresent instance].uid;
    msg.receiver = self.currentConversation.cid;
    
    MessageContent *content = [[MessageContent alloc] init];
    content.raw = text;
    msg.content = content;
    msg.timestamp = time(NULL);
    
    [self insertMsgToMessageBlokArray: msg];
    BOOL r = [[IMService instance] sendPeerMessage:msg];
    NSLog(@"send result:%d", r);
    
    [JSMessageSoundEffect playMessageSentSound];
    
    NSNotification* notification = [[NSNotification alloc] initWithName:SEND_FIRST_MESSAGE_OK object: msg userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:SEND_FIRST_MESSAGE_OK object: notification ];
    
    [self finishSend];
    
}

- (void)cameraPressed:(id)sender{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:NULL];
}

- (JSBubbleMessageType)messageTypeForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *array = [self.messageArray objectAtIndex: indexPath.section];
    IMessage * msg =  [array objectAtIndex:indexPath.row];
    if(msg.sender == [UserPresent instance].uid){
        return JSBubbleMessageTypeOutgoing;
    }else{
        return JSBubbleMessageTypeIncoming;
    }
    
}

- (JSBubbleMessageStyle)messageStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return JSBubbleMessageStyleFlat;
}

- (JSBubbleMediaType)messageMediaTypeForRowAtIndexPath:(NSIndexPath *)indexPath{
    return JSBubbleMediaTypeText;
}

- (UIButton *)sendButton
{
    return [UIButton defaultSendButton];
}

- (JSInputBarStyle)inputBarStyle
{
    /*
     JSInputBarStyleDefault,
     JSInputBarStyleFlat
     
     */
    return JSInputBarStyleFlat;
}

//  Optional delegate method
//  Required if using `JSMessagesViewTimestampPolicyCustom`
//
//  - (BOOL)hasTimestampForRowAtIndexPath:(NSIndexPath *)indexPath
//

#pragma mark - Messages view data source
- (NSString *)textForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *array = [self.messageArray objectAtIndex: indexPath.section];
    
    if([array objectAtIndex:indexPath.row]){
        return ((IMessage*)[array objectAtIndex:indexPath.row]).content.raw;
    }
    return nil;
}

- (NSDate *)timestampForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.timestamps objectAtIndex:indexPath.row];
}

- (UIImage *)avatarImageForIncomingMessage
{
    return [UIImage imageNamed:@"head1.png"];
}

- (UIImage *)avatarImageForOutgoingMessage
{
    return [UIImage imageNamed:@"head2.png"];
}

- (id)dataForRowAtIndexPath:(NSIndexPath *)indexPath{
    //  if([[self.messageArray objectAtIndex:indexPath.row] objectForKey:@"Image"]){
    //    return [[self.messageArray objectAtIndex:indexPath.row] objectForKey:@"Image"];
    //  }
    return nil;
    
}

#pragma UIImagePicker Delegate

#pragma mark - Image picker delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	NSLog(@"Chose image!  Details:  %@", info);
    
    self.willSendImage = [info objectForKey:UIImagePickerControllerEditedImage];
    //  [self.messageArray addObject:[NSDictionary dictionaryWithObject:self.willSendImage forKey:@"Image"]];
    [self.timestamps addObject:[NSDate date]];
    [self.tableView reloadData];
    [self scrollToBottomAnimated:YES];
    
	
    [self dismissViewControllerAnimated:YES completion:NULL];
    
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    
}


- (void)navBarUserheadAction{
    NSLog(@"头像");
    
    MessageShowThePotraitViewController *controller = [[MessageShowThePotraitViewController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
    
}

- (void) processConversationData{
    
    self.messageArray = [NSMutableArray array];
    self.timestamps = [NSMutableArray array];
    
    NSDate *lastDate = nil;
    NSDate *curtDate = nil;
    NSMutableArray *msgBlockArray = nil;
    IMessageIterator* iterator =  [[MessageDB instance] newPeerMessageIterator: self.currentConversation.cid];
    IMessage *msg = [iterator next];
    while (msg) {
        curtDate = [NSDate dateWithTimeIntervalSince1970: msg.timestamp];
        
        if (lastDate == nil) {
            //first
            msgBlockArray  = [[NSMutableArray alloc] init];
            [self.messageArray addObject: msgBlockArray];
            [msgBlockArray addObject:msg];
            
            [self.timestamps addObject: curtDate];
            lastDate = curtDate;
            
        }
        if ([PublicFunc isTheDay:lastDate sameToThatDay:curtDate]) {
            //同一天
            [msgBlockArray addObject:msg];
        }else{
            //新一天
            msgBlockArray  = [[NSMutableArray alloc] init];
            [self.messageArray addObject: msgBlockArray];
            [msgBlockArray addObject:msg];
            
            [self.timestamps addObject: curtDate];
            lastDate = curtDate;
        }
        msg = [iterator next];
    }
}

-(void) insertMsgToMessageBlokArray:(IMessage*)msg{
    
    [[MessageDB instance] insertPeerMessage:msg uid:msg.sender];
    NSDate *curtDate = [NSDate dateWithTimeIntervalSince1970: msg.timestamp];
    NSMutableArray *msgBlockArray = nil;
    //收到第一个消息
    if ([self.messageArray count] == 0 ) {
        
        msgBlockArray = [[NSMutableArray alloc] init];
        [self.messageArray addObject: msgBlockArray];
        [msgBlockArray addObject:msg];
        
        [self.timestamps addObject: curtDate];
    }else{
        NSDate *lastDate = [self.timestamps lastObject];
        if ([PublicFunc isTheDay: lastDate sameToThatDay: curtDate]) {
            //same day
            msgBlockArray = [self.messageArray lastObject];
            [msgBlockArray addObject:msg];
        }else{
            //next day
            msgBlockArray = [[NSMutableArray alloc] init];
            [msgBlockArray addObject: msg];
            [self.messageArray addObject: msgBlockArray];
            [self.timestamps addObject:curtDate];
        }
    }
}

@end
