//
//  ChatRoom.m
//  Server
//
//  Created by John Setting on 12/11/13.
//  Copyright (c) 2013 John Setting. All rights reserved.
//

#import "ChatRoom.h"
@implementation ChatRoom

- (id) init {
    return [self initWithName:nil host:nil];
}

- (id) initWithHost:(GCDAsyncSocket *)host {
    return [self initWithName:nil host:host];
}

- (id) initWithName:(NSString *)chatRoomName host:(GCDAsyncSocket *)host {
    if ([self = self initWithName:chatRoomName host:host]) {
        self.chatRoomName = chatRoomName;
        self.host = host;
        self.chatRoomClients = [NSMutableArray array];
    }
    return self;
}


@end
