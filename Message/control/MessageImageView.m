
//
//  MessageImageView.m
//  Message
//
//  Created by houxh on 14-9-9.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import "MessageImageView.h"
#import "ESImageViewController.h"

#define kImageWidth  100
#define kImageHeight 100

#define KInComingMoveRight  8.0
#define kOuttingMoveRight   3.0

@implementation MessageImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView = [[UIImageView alloc] init];
        [self.imageView setUserInteractionEnabled:YES];
        [self addSubview:self.imageView];
    }
    return self;
}

- (void) setDelegte:(UIViewController*)del{
    
    self.dgtController = del;
    UITapGestureRecognizer *tap  = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [tap setNumberOfTouchesRequired: 1];
    [self.imageView addGestureRecognizer: tap];
    
}

- (void)setData:(id)newData{
    _data = newData;
    
    if (_data) {
        if(![[SDImageCache sharedImageCache] diskImageExistsWithKey:_data]){
            self.loadIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            self.loadIndicatorView.hidesWhenStopped = YES;
            CGRect bubbleFrame = [self bubbleFrame];
            [self.loadIndicatorView setFrame: bubbleFrame];
            [self.loadIndicatorView startAnimating];
            [self addSubview: self.loadIndicatorView];
        }
        [self.imageView sd_setImageWithURL: [[NSURL alloc] initWithString:_data] placeholderImage:[UIImage imageNamed:@"GroupChatRound"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            if (self.loadIndicatorView&&[self.loadIndicatorView isAnimating]) {
                [self.loadIndicatorView stopAnimating];
                [self.loadIndicatorView removeFromSuperview];
            }
        }];
    }
    
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)frame{
    [super drawRect:frame];
    
	UIImage *image = (self.selectedToShowCopyMenu) ? [self bubbleImageHighlighted] : [self bubbleImage];
    
    CGRect bubbleFrame = [self bubbleFrame];
	[image drawInRect:bubbleFrame];
    
    [self drawMsgStateSign: frame];
    
    if (self.imageView) {
        
        CGSize imageSize = CGSizeMake(kImageWidth, kImageHeight);
        CGFloat imgX = image.leftCapWidth + (self.type == BubbleMessageTypeOutgoing ? bubbleFrame.origin.x + kOuttingMoveRight: KInComingMoveRight);
        
        CGRect imageFrame = CGRectMake(imgX,
                                       kPaddingTop + kMarginTop,
                                       imageSize.width - kPaddingTop - kMarginTop,
                                       imageSize.height - kPaddingBottom + 2.f);
        [self.imageView setFrame:imageFrame];
        
    }
}


#pragma mark - Drawing
- (CGRect)bubbleFrame {
    CGSize bubbleSize = CGSizeMake(kImageWidth + 35, kImageHeight + 15);
    return CGRectMake(floorf(self.type == BubbleMessageTypeOutgoing ? self.frame.size.width - bubbleSize.width : 0.0f),
                      floorf(kMarginTop),
                      floorf(bubbleSize.width),
                      floorf(bubbleSize.height));
    
}


- (void) handleTap:(UITapGestureRecognizer*)tap{
    if (self.dgtController) {
        if ([tap.view isKindOfClass:[UIImageView class]]) {
            if ([[SDImageCache sharedImageCache] diskImageExistsWithKey:self.data]) {
                UIImage *cacheImg = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey: self.data];
                ESImageViewController * imgcontroller = [[ESImageViewController alloc] init];
                [imgcontroller setImage:cacheImg];
                [imgcontroller setTappedThumbnail:self];
                [self.dgtController presentViewController:imgcontroller animated:YES completion:nil];
            }
        }
    }
}

-(void) setUploading:(BOOL)uploading {
    //uploading的动画
    if (uploading) {
        self.isUpLoad = YES;
        self.loadIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.loadIndicatorView.hidesWhenStopped = YES;
        CGRect bubbleFrame = [self bubbleFrame];
        
        UIImage *image = (self.selectedToShowCopyMenu) ? [self bubbleImageHighlighted] : [self bubbleImage];
        bubbleFrame.origin.x -= image.leftCapWidth;
        
        [self.loadIndicatorView setFrame: bubbleFrame];
        [self.loadIndicatorView startAnimating];
        [self addSubview: self.loadIndicatorView];
    }else{
        self.isUpLoad = NO;
        if (self.loadIndicatorView&&[self.loadIndicatorView isAnimating]) {
            [self.loadIndicatorView stopAnimating];
        }
    }
}
@end