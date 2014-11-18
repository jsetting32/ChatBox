//
//  AppDelegate.h
//  Client
//
//  Created by John Setting on 12/3/13.
//  Copyright (c) 2013 John Setting. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GCDAsyncSocket.h"
@class MainWindowController;

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    IBOutlet NSMenuItem *new_MenuItem;
}

@property (strong, nonatomic) MainWindowController *mainController;

- (IBAction)newWindow:(id)sender;

@end
