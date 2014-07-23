//
//  PeerMessageDB.m
//  Message
//
//  Created by houxh on 14-7-22.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import "PeerMessageDB.h"
#import "MessageDB.h"
#include <sys/stat.h>
#include <dirent.h>
#import "ReverseFile.h"


@interface PeerMessageIterator()
@property(nonatomic)ReverseFile *file;
-(id)initWithPath:(NSString*)path;
@end


@implementation PeerMessageIterator

-(id)initWithPath:(NSString*)path {
    self = [super init];
    if (self) {
        [self openFile:path];
    }
    return self;
}

-(void)openFile:(NSString*)path {
    
    int fd = open([path UTF8String], O_RDONLY);
    if (fd == -1) {
        NSLog(@"open file fail:%@", path);
        return;
    }
    if (![MessageDB checkHeader:fd]) {
        close(fd);
        return;
    }
    self.file = [[ReverseFile alloc] initWithFD:fd];
}

-(IMessage*)nextMessage {
    if (!self.file) return nil;
    return [MessageDB readMessage:self.file];
}

-(IMessage*)next {
    while (YES) {
        IMessage *msg = [self nextMessage];
        if (msg.flags & MESSAGE_FLAG_DELETE) {
            continue;
        }
        return msg;
    }
}
@end


@implementation PeerMessageDB
+(PeerMessageDB*)instance {
    static PeerMessageDB *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!m) {
            m = [[PeerMessageDB alloc] init];
        }
    });
    return m;
}

-(id)init {
    self = [super init];
    if (self) {
        NSString *path = [self getMessagePath];
        int r = mkdir([path UTF8String], 0755);
        if (r == -1 && errno != EEXIST) {
            NSLog(@"mkdir error:%d", errno);
        }
    }
    return self;
}

-(NSString*)getMessagePath {
    NSString *s = [MessageDB getDocumentPath];
    return [NSString stringWithFormat:@"%@/peer", s];
}
-(NSString*)getPeerPath:(int64_t)uid {
    NSString *s = [MessageDB getDocumentPath];
    return [NSString stringWithFormat:@"%@/peer/p_%lld", s, uid];
}


-(BOOL)insertPeerMessage:(IMessage*)msg uid:(int64_t)uid{
    NSString *path = [self getPeerPath:uid];
    return [MessageDB insertIMessage:msg path:path];
}

-(BOOL)removePeerMessage:(int)msgLocalID uid:(int64_t)uid{
    NSString *path = [self getPeerPath:uid];
    return [MessageDB addFlag:msgLocalID path:path flag:MESSAGE_FLAG_DELETE];
}

-(BOOL)clearConversation:(int64_t)uid {
    NSString *path = [self getPeerPath:uid];
    int r = unlink([path UTF8String]);
    if (r == -1) {
        NSLog(@"unlink error:%d", errno);
        return (errno == ENOENT);
    }
    return YES;
}

-(BOOL)clear {
    NSString *path = [[PeerMessageDB instance] getMessagePath];
    DIR *dirp = opendir([path UTF8String]);
    if (dirp == NULL) {
        NSLog(@"readdir error:%d", errno);
        return NO;
    }

    struct dirent *dp;
    while ((dp = readdir(dirp)) != NULL) {
        NSString *name = [[NSString alloc] initWithBytes:dp->d_name length:dp->d_namlen encoding:NSUTF8StringEncoding];
        NSLog(@"type:%d name:%@", dp->d_type, name);
        if (dp->d_type == DT_REG) {
            if ([name hasPrefix:@"p_"]) {
                int64_t uid = [[name substringFromIndex:2] longLongValue];
                NSString *path = [self getPeerPath:uid];
                unlink([path UTF8String]);
            } else {
                NSLog(@"skip file:%@", name);
            }
        }
    }
    return YES;
}

-(BOOL)acknowledgePeerMessage:(int)msgLocalID uid:(int64_t)uid {
    NSString *path = [self getPeerPath:uid];
    return [MessageDB addFlag:msgLocalID path:path flag:MESSAGE_FLAG_ACK];
}

-(BOOL)acknowledgePeerMessageFromRemote:(int)msgLocalID uid:(int64_t)uid {
    NSString *path = [self getPeerPath:uid];
    return [MessageDB addFlag:msgLocalID path:path flag:MESSAGE_FLAG_PEER_ACK];
}

-(BOOL)markPeerMessageFailure:(int)msgLocalID uid:(int64_t)uid {
    NSString *path = [self getPeerPath:uid];
    return [MessageDB addFlag:msgLocalID path:path flag:MESSAGE_FLAG_FAILURE];
}


-(id<IMessageIterator>)newPeerMessageIterator:(int64_t)uid {
    NSString *path = [self getPeerPath:uid];
    return [[PeerMessageIterator alloc] initWithPath:path];
}

-(id<ConversationIterator>)newConversationIterator {
    return [[PeerConversationIterator alloc] init];
}

@end


@interface PeerConversationIterator()
@property(nonatomic, assign)DIR *dirp;
@end

@implementation PeerConversationIterator
-(id)init {
    self = [super init];
    if (self) {
        [self openDir];
    }
    return self;
}

-(void)dealloc {
    if (self.dirp) {
        closedir(self.dirp);
    }
}
-(void)openDir {
    NSString *path = [[PeerMessageDB instance] getMessagePath];
    DIR *dirp = opendir([path UTF8String]);
    if (dirp == NULL) {
        NSLog(@"readdir error:%d", errno);
        return;
    }
    self.dirp = dirp;
}

-(IMessage*)getLastPeerMessage:(int64_t)uid {
    id<IMessageIterator> iter = [[PeerMessageDB instance] newPeerMessageIterator:uid];
    IMessage *msg;
    msg = [iter next];
    return msg;
}

-(Conversation*)next {
    if (!self.dirp) return nil;
    
    struct dirent *dp;
    while ((dp = readdir(self.dirp)) != NULL) {
        NSString *name = [[NSString alloc] initWithBytes:dp->d_name length:dp->d_namlen encoding:NSUTF8StringEncoding];
        NSLog(@"type:%d name:%@", dp->d_type, name);
        if (dp->d_type == DT_REG) {
            if ([name hasPrefix:@"p_"]) {
                Conversation *c = [[Conversation alloc] init];
                int64_t uid = [[name substringFromIndex:2] longLongValue];
                c.cid = uid;
                c.type = CONVERSATION_PEER;
                c.message = [self getLastPeerMessage:uid];
                if (c.message) return c;
            } else if ([name hasPrefix:@"g_"]) {
                
            } else {
                NSLog(@"skip file:%@", name);
            }
        }
    }
    return nil;
}
@end


