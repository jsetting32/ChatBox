//
//  AppDelegate.h
//  Server
//
//  Created by John Setting on 12/3/13.
//  Copyright (c) 2013 John Setting. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class ServerWindowController;

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (strong, nonatomic) ServerWindowController *serverController;
@end
