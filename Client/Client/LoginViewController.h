//
//  LoginViewController.h
//  Client
//
//  Created by John Setting on 12/14/13.
//  Copyright (c) 2013 John Setting. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LoginViewController : NSViewController
{
    IBOutlet id hostField;
    IBOutlet id portField;
    IBOutlet id displayNameField;
}

- (NSString *)getHostField;
- (void)hideHostField:(BOOL)hide;

- (NSInteger)getPortField;
- (void)hidePortField:(BOOL)hide;

- (NSString *)getDisplayNameField;
- (void)hideDisplayNameField:(BOOL)hide;

@end
