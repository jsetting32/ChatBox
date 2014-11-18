//
//  AppDelegate.m
//  Client
//
//  Created by John Setting on 12/3/13.
//  Copyright (c) 2013 John Setting. All rights reserved.
//

#import "AppDelegate.h"
#import "MainWindowController.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[self mainController] showWindow:self];
}


- (MainWindowController *)mainController {
    if (nil == _mainController) {
        _mainController = [[MainWindowController alloc] initWithWindowNibName:@"MainWindowController"];
    }
    return _mainController;
}


- (IBAction)newWindow:(id)sender {
	
}

@end
