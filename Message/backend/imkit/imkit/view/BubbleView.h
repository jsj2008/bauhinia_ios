#import <UIKit/UIKit.h>
#import "UIImageView+WebCache.h"
#import "BCTextView.h"

extern CGFloat const kJSAvatarSize;

#define kMarginTop 4.0f
#define kMarginBottom 4.0f
#define kPaddingTop 8.0f
#define kPaddingBottom 8.0f
#define kBubblePaddingRight 45.0f

typedef enum {
    BubbleMessageReceiveStateNone = 0,
    BubbleMessageReceiveStateServer,
    BubbleMessageReceiveStateClient
}BubbleMessageReceiveStateType;

typedef enum {
    BubbleMessageTypeIncoming = 0,
    BubbleMessageTypeOutgoing
} BubbleMessageType;


@interface BubbleView : UIView


@property (assign, nonatomic) BubbleMessageType type;
@property (assign, nonatomic) BOOL selectedToShowCopyMenu;
@property (nonatomic) BubbleMessageReceiveStateType msgStateType;
@property (nonatomic) UIImageView *receiveStateImgSign;
@property (nonatomic) UIActivityIndicatorView *downloadIndicatorView;
@property (nonatomic) UIActivityIndicatorView *uploadIndicatorView;
@property (nonatomic) CGRect contentFrame;
@property (strong, nonatomic) UIButton *msgSendErrorBtn;
@property (strong, nonatomic) UIImageView *msgSignImgView;
@property  (strong,nonatomic) UIImageView *bubleBKView;
@property (nonatomic, strong) BCTextView *bcTextView;


- (id)initWithFrame:(CGRect)frame withType:(BubbleMessageType)type;
#pragma mark - Drawing
- (CGRect)bubbleFrame;
- (UIImage *)bubbleImage;
- (UIImage *)bubbleImageHighlighted;

-(void) showSendErrorBtn:(BOOL)show;

#pragma mark - Bubble view
+ (UIImage *)bubbleImageForType:(BubbleMessageType)aType;

+ (UIFont *)font;

+ (CGSize)textSizeForText:(NSString *)txt;
+ (CGSize)bubbleSizeForText:(NSString *)txt;
+ (CGSize)bubbleSizeForImage:(UIImage *)image;
+ (CGSize)imageSizeForImage;
+ (CGFloat)cellHeightForText:(NSString *)txt;

+ (int)maxCharactersPerLine;
+ (int)numberOfLinesForMessage:(NSString *)txt;

@end