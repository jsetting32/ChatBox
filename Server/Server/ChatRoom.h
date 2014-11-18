//
//  ChatRoom.h
//  Server
//
//  Created by John Setting on 12/11/13.
//  Copyright (c) 2013 John Setting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
@interface ChatRoom : NSObject
- (id) initWithHost:(GCDAsyncSocket *)host;
- (id) initWithName:(NSString *)chatRoomName host:(GCDAsyncSocket *)host;

@property (nonatomic, strong) NSString *chatRoomName;
@property (nonatomic, strong) GCDAsyncSocket *host;
@property (nonatomic, strong) NSMutableArray *chatRoomClients;
@end
