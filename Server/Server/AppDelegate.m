//
//  AppDelegate.m
//  asdf
//
//  Created by John Setting on 12/11/13.
//  Copyright (c) 2013 John Setting. All rights reserved.
//

#import "AppDelegate.h"
#import "ServerWindowController.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [self.serverController showWindow:self];
}

- (ServerWindowController *)serverController {
    if (_serverController == nil) {
        _serverController = [[ServerWindowController alloc] initWithWindowNibName:@"ServerWindowController"];
    }
    return _serverController;
}

@end
