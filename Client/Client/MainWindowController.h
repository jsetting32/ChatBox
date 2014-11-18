//
//  MainWindowController.h
//  Client
//
//  Created by John Setting on 12/14/13.
//  Copyright (c) 2013 John Setting. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MainViewController.h"
#import "LoginViewController.h"

@class GCDAsyncSocket;

@interface MainWindowController : NSWindowController
{
    dispatch_queue_t        socketQueue;
	
	GCDAsyncSocket      *   selfSocket;
        
    NSViewController    *   subViewController;
    IBOutlet NSView     *   subView;
    
    IBOutlet id             connectButton;
    
    BOOL isRunning;
}

- (IBAction)connectAction:(id)sender;

@property (nonatomic, strong) LoginViewController *loginViewController;
@property (nonatomic, strong) MainViewController *mainViewController;

@end
